# Operacao local e producao

## Inicializacao local

No WSL Ubuntu, com o Docker Desktop integrado:

```bash
docker compose up -d postgres
bundle install
bin/rails db:prepare
bin/rails server -b 0.0.0.0
```

Em outro processo, execute o worker da fila:

```bash
bin/jobs start
```

O frontend separado inicia com `npm run dev -- --host 0.0.0.0` na porta 8080.
Valide `GET /up` e `GET /api/v1/health` antes de testar os fluxos.

## Variaveis obrigatorias

Produção exige `DATABASE_URL`, `RAILS_MASTER_KEY`, `DEVISE_JWT_SECRET_KEY`,
`CORS_ORIGINS`, `ACTIVE_STORAGE_SERVICE=amazon`, região e bucket S3, SMTP,
`APP_HOST` e uma URL HTTPS. O bucket deve ser privado por padrão, com IAM
limitado ao bucket via role da EC2 (sem chaves de longa duração) e CloudFront/CDN
configurado para os arquivos públicos.

Use `AWS_S3_BUCKET_DEVELOPMENT`, `AWS_S3_BUCKET_STAGING` e
`AWS_S3_BUCKET_PRODUCTION` para manter os ambientes isolados. `AWS_S3_BUCKET`
continua disponível como fallback para ambientes legados.

Antes do deploy, execute `RAILS_ENV=production bin/rails production:check` para
validar as variáveis obrigatórias sem expor os valores ou fazer chamadas externas.

## Backup e recuperacao

Use backup gerenciado do PostgreSQL com retenção definida pelo ambiente. Para um
backup manual:

```bash
pg_dump "$DATABASE_URL" --format=custom --file=backup.dump
pg_restore --clean --if-exists --dbname="$DATABASE_URL" backup.dump
```

Antes de restaurar, interrompa web, worker e scheduler, valide o arquivo em um
ambiente isolado e registre o incidente. Arquivos do Active Storage devem ser
protegidos por versionamento/lifecycle do bucket e testados junto com o banco.

## Deploy e rollback

1. Executar migrations e checks em staging.
2. Publicar a mesma imagem/commit em produção.
3. Confirmar health checks, fila, storage e envio de teste.
4. Em falha, interromper novos dispatches, retornar à imagem anterior e manter
   o banco somente com migrations retrocompatíveis.
5. Reprocessar jobs falhos depois de confirmar idempotência.

Web, worker e scheduler devem ser processos separados em produção. Logs não
devem conter tokens JWT, senhas, conteúdo de autorização ou PII além do mínimo
necessário para diagnóstico.

No Kamal, o processo `web` executa o Puma e o processo `job` executa `bin/jobs`.
O scheduler do Solid Queue é iniciado pelo próprio worker; não habilite
`SOLID_QUEUE_IN_PUMA` em produção. O health check de fila valida a conexão do
 banco dedicado quando o adapter Solid Queue está ativo.

## Tráfego do site

O frontend registra visitas das páginas públicas e cliques em links internos em
`POST /api/v1/site_analytics_events`. O relatório privado fica em
`GET /api/v1/admin/site_analytics` e na tela `/app/site-analytics`, acessível
somente a administradores. Não há dependência de Google Analytics ou Meta Pixel.

Os eventos guardam caminho da página sem query string, ID temporário da sessão
da aba, domínio de referência, parâmetros UTM e tipo de dispositivo. Não guarde
IP, e-mail ou conteúdo dos formulários nessa tabela. O navegador respeita os
sinais Do Not Track e Global Privacy Control. O scheduler remove eventos com
mais de 90 dias; mantenha o processo `job` ativo em produção para executar a
limpeza. Publique a migration do backend antes do frontend que envia eventos.
