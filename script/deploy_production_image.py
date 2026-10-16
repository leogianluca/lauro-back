#!/usr/bin/env python3
"""Replace the standalone production containers with a pre-pulled image.

Run on the EC2 host as root. Existing container environment values are kept in
an ephemeral /run file and never printed. Previous containers remain for rollback.
"""

import argparse
import fcntl
import json
import os
import subprocess
import tempfile
import time
import urllib.request


NAMES = ("lauro-web", "lauro-jobs")


def run(*args):
    result = subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode:
        raise RuntimeError(f"{args[0]} {args[1] if len(args) > 1 else ''} failed ({result.returncode})")


def inspect(name):
    return json.loads(subprocess.check_output(["docker", "inspect", name], text=True))[0]


def exists(name):
    return subprocess.run(
        ["docker", "inspect", name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    ).returncode == 0


def wait_http(port, path, seconds=120):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}{path}", timeout=5) as response:
                if response.status == 200:
                    return
        except Exception:
            pass
        time.sleep(2)
    raise RuntimeError(f"HTTP check failed on port {port}: {path}")


def start(name, original, env_file, image, candidate=False):
    command = [
        "docker", "run", "-d", "--name", name, "--env-file", env_file,
        "--user", "1000:1000", "--workdir", "/rails", "--log-driver", "json-file",
    ]
    if not candidate:
        command += ["--restart", "unless-stopped"]
    for key, value in original["HostConfig"]["LogConfig"]["Config"].items():
        command += ["--log-opt", f"{key}={value}"]
    if name.startswith("lauro-web"):
        command += ["--publish", "127.0.0.1:8081:80" if candidate else "80:80"]
    command += [image, *original["Config"]["Cmd"]]
    run(*command)


def rollback(backups):
    for name, backup in reversed(backups):
        if exists(name):
            run("docker", "rm", "-f", name)
        if exists(backup):
            run("docker", "rename", backup, name)
            if not inspect(name)["State"]["Running"]:
                run("docker", "start", name)


def deploy(image, tag):
    os.umask(0o077)
    with open("/run/lauro-deploy.lock", "w", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        originals = {name: inspect(name) for name in NAMES}
        if len({item["Config"]["Image"] for item in originals.values()}) != 1:
            raise RuntimeError("Web and jobs use different images")
        for name, config in originals.items():
            host = config["HostConfig"]
            if (
                config["Mounts"] or host["NetworkMode"] != "default"
                or host["RestartPolicy"]["Name"] != "unless-stopped"
                or config["Config"]["User"] != "1000:1000"
                or config["Config"]["WorkingDir"] != "/rails"
            ):
                raise RuntimeError(f"Unexpected container configuration: {name}")
        if originals["lauro-web"]["HostConfig"]["PortBindings"] != {
            "80/tcp": [{"HostIp": "", "HostPort": "80"}]
        }:
            raise RuntimeError("Unexpected web port binding")
        if originals["lauro-jobs"]["HostConfig"]["PortBindings"] != {}:
            raise RuntimeError("Unexpected jobs port binding")
        env_files = {}
        candidate = f"lauro-web-candidate-{tag}"
        backups = []
        try:
            for name in NAMES:
                fd, env_file = tempfile.mkstemp(prefix="lauro-deploy-", suffix=".env", dir="/run")
                env_files[name] = env_file
                with os.fdopen(fd, "w", encoding="utf-8") as stream:
                    for entry in originals[name]["Config"]["Env"]:
                        if "\n" in entry or "\r" in entry:
                            raise RuntimeError("Multiline environment entry")
                        stream.write(entry + "\n")
                os.chmod(env_file, 0o600)

            print("Applying database migrations", flush=True)
            run(
                "docker", "run", "--rm", "--env-file", env_files["lauro-web"], "--user", "1000:1000",
                "--workdir", "/rails", image, "./bin/rails", "db:migrate",
            )
            print("Checking candidate web container", flush=True)
            start(candidate, originals["lauro-web"], env_files["lauro-web"], image, candidate=True)
            wait_http(8081, "/up")
            wait_http(8081, "/api/v1/health")
            wait_http(8081, "/api/v1/investment_cards?category=residential&page=1&per_page=1")
            run("docker", "rm", "-f", candidate)
            print("Candidate checks passed", flush=True)

            for name in NAMES:
                backup = f"{name}-predeploy-{tag}"
                if exists(backup):
                    raise RuntimeError(f"Backup name already exists: {backup}")
                run("docker", "rename", name, backup)
                backups.append((name, backup))
                run("docker", "stop", backup)
                start(name, originals[name], env_files[name], image)
                if name == "lauro-web":
                    wait_http(80, "/up")
                    wait_http(80, "/api/v1/health")
                    wait_http(80, "/api/v1/investment_cards?category=residential&page=1&per_page=1")
                else:
                    time.sleep(8)
                    if not inspect(name)["State"]["Running"]:
                        raise RuntimeError("Jobs container exited")
                print(f"Deployed {name}", flush=True)
            print("Deployment complete; rollback containers retained: " +
                  ", ".join(backup for _, backup in backups), flush=True)
        except Exception:
            if exists(candidate):
                run("docker", "rm", "-f", candidate)
            rollback(backups)
            print("Rollback completed", flush=True)
            raise
        finally:
            for env_file in env_files.values():
                os.unlink(env_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--tag", required=True)
    arguments = parser.parse_args()
    deploy(arguments.image, arguments.tag)
