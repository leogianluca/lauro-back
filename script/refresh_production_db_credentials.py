#!/usr/bin/env python3
"""Refresh the standalone production Docker containers after an RDS secret rotation.

Run on the production EC2 host as root. The instance role needs permission to read
the RDS managed secret. No secret value is written to stdout or a persistent file.
"""

import argparse
import fcntl
import json
import os
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


CONTAINERS = ("lauro-web", "lauro-jobs")
DATABASE_URL_KEYS = (
    "DATABASE_URL",
    "QUEUE_DATABASE_URL",
    "CACHE_DATABASE_URL",
    "CABLE_DATABASE_URL",
)


def output(*command):
    return subprocess.check_output(command, text=True, stderr=subprocess.DEVNULL)


def run(*command):
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def inspect(name):
    return json.loads(output("docker", "inspect", name))[0]


def environment(config):
    return dict(item.split("=", 1) for item in config["Config"]["Env"] if "=" in item)


def current_secret(secret_arn):
    response = json.loads(
        output(
            "aws", "secretsmanager", "get-secret-value", "--region", "us-east-1",
            "--secret-id", secret_arn,
        )
    )
    secret = json.loads(response["SecretString"])
    if not secret.get("username") or not secret.get("password"):
        raise RuntimeError("RDS secret is missing a required field")
    return secret


def refreshed_url(raw_url, secret, expected_host):
    parsed = urllib.parse.urlsplit(raw_url)
    if parsed.scheme not in ("postgres", "postgresql"):
        raise RuntimeError("Unexpected database URL scheme")
    if urllib.parse.unquote(parsed.username or "") != secret["username"]:
        raise RuntimeError("Database user differs from the RDS secret")
    if parsed.hostname != expected_host:
        raise RuntimeError("Database host differs from the expected RDS endpoint")
    if "@" not in parsed.netloc:
        raise RuntimeError("Database URL has no credentials")
    user_info, host_info = parsed.netloc.rsplit("@", 1)
    username = user_info.split(":", 1)[0]
    netloc = f"{username}:{urllib.parse.quote(secret['password'], safe='')}@{host_info}"
    return urllib.parse.urlunsplit(parsed._replace(netloc=netloc))


def prepare_environment(config, secret, expected_host):
    env = environment(config)
    changed = False
    for key in DATABASE_URL_KEYS:
        if key not in env:
            raise RuntimeError(f"Missing {key} in container configuration")
        updated = refreshed_url(env[key], secret, expected_host)
        changed |= updated != env[key]
        env[key] = updated
    return env, changed


def write_environment(env):
    fd, path = tempfile.mkstemp(prefix="lauro-db-", suffix=".env", dir="/run")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            for key, value in env.items():
                if "\n" in key or "\n" in value or "\r" in value:
                    raise RuntimeError("Multiline container environment is unsupported")
                stream.write(f"{key}={value}\n")
        os.chmod(path, 0o600)
        return path
    except Exception:
        Path(path).unlink(missing_ok=True)
        raise


def assert_supported_config(name, config):
    container = config["Config"]
    host = config["HostConfig"]
    expected_ports = {"80/tcp": [{"HostIp": "", "HostPort": "80"}]} if name == "lauro-web" else {}
    if (
        config["Mounts"]
        or host["NetworkMode"] != "default"
        or host["PortBindings"] != expected_ports
        or host["RestartPolicy"]["Name"] != "unless-stopped"
        or host["LogConfig"]["Type"] != "json-file"
        or container["Entrypoint"] != ["/rails/bin/docker-entrypoint"]
        or container["User"] != "1000:1000"
        or container["WorkingDir"] != "/rails"
    ):
        raise RuntimeError(f"{name} has an unexpected Docker configuration; refusing to recreate it")


def preflight(config, env_file):
    image = config["Config"]["Image"]
    run(
        "docker", "run", "--rm", "--env-file", env_file,
        image, "./bin/rails", "runner",
        "ActiveRecord::Base.connection.select_value('SELECT 1')",
    )


def start_container(name, config, env_file):
    host = config["HostConfig"]
    command = [
        "docker", "run", "-d", "--name", name, "--restart", "unless-stopped",
        "--env-file", env_file, "--user", "1000:1000", "--workdir", "/rails",
        "--log-driver", "json-file",
    ]
    for key, value in host["LogConfig"]["Config"].items():
        command.extend(["--log-opt", f"{key}={value}"])
    if name == "lauro-web":
        command.extend(["--publish", "80:80"])
    command.extend([config["Config"]["Image"], *config["Config"]["Cmd"]])
    run(*command)


def wait_for_web():
    url = "http://127.0.0.1/api/v1/investment_cards?category=residential&page=1&per_page=1"
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=5) as response:
                if response.status == 200 and "data" in json.load(response):
                    return
        except (OSError, ValueError, urllib.error.HTTPError):
            pass
        time.sleep(2)
    raise RuntimeError("Web API did not become healthy after database credential refresh")


def replace(name, config, env_file):
    backup = f"{name}-before-db-refresh-{int(time.time())}"
    run("docker", "rename", name, backup)
    try:
        run("docker", "stop", backup)
        start_container(name, config, env_file)
        if name == "lauro-web":
            wait_for_web()
        else:
            time.sleep(5)
            if not inspect(name)["State"]["Running"]:
                raise RuntimeError("Jobs container exited after database credential refresh")
    except Exception:
        subprocess.run(["docker", "rm", "-f", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        run("docker", "rename", backup, name)
        run("docker", "start", name)
        raise
    run("docker", "rm", backup)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--secret-arn", required=True)
    parser.add_argument("--db-host", required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    os.umask(0o077)

    with open("/run/lauro-db-refresh.lock", "w", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        secret = current_secret(args.secret_arn)
        pending = []
        for name in CONTAINERS:
            config = inspect(name)
            assert_supported_config(name, config)
            env, changed = prepare_environment(config, secret, args.db_host)
            if changed:
                pending.append((name, config, env))

        if not pending:
            print("Database credentials already match the current RDS secret")
            return
        print("Containers requiring a database credential refresh: " + ", ".join(item[0] for item in pending))
        if not args.apply:
            return

        staged = []
        try:
            for name, config, env in pending:
                env_file = write_environment(env)
                staged.append((name, config, env_file))
            preflight(staged[0][1], staged[0][2])
            for name, config, env_file in staged:
                replace(name, config, env_file)
                print(f"Refreshed {name}")
        finally:
            for _, _, env_file in staged:
                Path(env_file).unlink(missing_ok=True)


if __name__ == "__main__":
    main()
