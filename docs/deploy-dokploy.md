# Deploy com Dokploy (recomendado)

## Ideia

A VPS **nunca builda**. GitHub publica imagens no GHCR → Dokploy só **puxa e sobe**.

Serviços: **`api`** + **`web`** (site) + **`app`** (Flutter membros / iOS) + **`postgres-db`**.

- **Domínio:** só na aba **Domains** do Dokploy (não no compose)
- **URL da API no site:** variável de ambiente **`WEB_API_URL`**
- **App Flutter web:** `API_URL` entra na **build** da imagem (`--dart-define`); o compose usa o mesmo valor de `WEB_API_URL` no `docker-compose.build.yml`

```
Browser → domínio do site (Dokploy) → container `web` (nginx)
Browser → domínio do app (Dokploy) → container `app` (serve :8080)
                │
                └─ site: config.js / app: dart-define → API pública
```

---

## Passo 1 — Imagens no GHCR

1. `main` com Docker Publish verde (`api` + `web` + `app`)
2. Packages **Public**: `church-app/api`, `church-app/web`, `church-app/app`

## Passo 2 — Compose no Dokploy

1. App tipo **Docker Compose**
2. Compose file: `docker-compose.yml`
3. Branch `main`, **sem** “Build on deploy”
4. Redeploy / Deploy

### Dois (ou mais) projetos com o mesmo código

Cada app no Dokploy é um stack separado. O compose **não** fixa `container_name`, então o Docker gera nomes com o prefixo do projeto (ex.: `ipi-avare-api-1`, `outra-igreja-api-1`).

Para nomes legíveis e sem colisão, defina em **cada** app um `COMPOSE_PROJECT_NAME` diferente no Environment:

| App Dokploy     | `COMPOSE_PROJECT_NAME` |
|-----------------|------------------------|
| Igreja A        | `ipi-avare`            |
| Igreja B        | `igreja-b`             |

Também use env distinto por igreja (`POSTGRES_*`, `JWT_SECRET`, `WEB_API_URL`, `CORS_ORIGIN`, domínios na aba Domains). Volume e rede interna (`church-app-network`) ficam isolados por projeto.

`dokploy-network` é **compartilhada** em toda a VPS (Traefik). Por isso só `api` / `web` / `app` entram nela — **não** o `postgres-db`. Se o Postgres também entrasse, o alias DNS `postgres-db` colidiria entre App1 e App2 (mesmo em projetos Dokploy diferentes) e a API veria dois bancos.

## Passo 3 — Environment (Dokploy)

Defina no painel (grava `.env` do compose):

```env
# Opcional, mas recomendado se você sobe 2+ apps do mesmo repo
COMPOSE_PROJECT_NAME=ipi-avare

POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_DB=church_db
JWT_SECRET=...

# Origem(ns) do site e do app (domínios na aba Domains)
CORS_ORIGIN=https://seu-dominio.com.br,https://www.seu-dominio.com.br,https://app.seu-dominio.com.br

# URL pública da API (o browser do visitante chama isso)
WEB_API_URL=https://api.seu-dominio.com.br
```

No start do container `web`, `WEB_API_URL` vira `/config.js` → `window.__ENV__.API_URL`.  
A imagem `app` já sai com `API_URL` compilado (rebuild/publish para mudar).

## Passo 4 — Domains (Dokploy)

Na aba **Domains**, adicione:

| Domínio              | Serviço | Porta |
|----------------------|---------|-------|
| `api.seu-dominio...` | `api`   | 3030  |
| `seu-dominio...`     | `web`   | 80    |
| `www.seu-dominio...` | `web`   | 80    |
| `app.seu-dominio...` | `app`   | 8080  |

O Dokploy injeta Traefik + TLS. **Não** é preciso label `Host(...)` no `docker-compose.yml`.

Depois: **Deploy** de novo se o domínio foi adicionado após o primeiro up.

---

## Conferência

| Serviço       | Imagem                         | Porta do container |
|---------------|--------------------------------|--------------------|
| `api`         | `.../church-app/api`           | 3030               |
| `web`         | `.../church-app/web`           | 80                 |
| `app`         | `.../church-app/app`           | 8080               |
| `postgres-db` | `postgres:16-alpine`           | 5432               |

Logs do site devem mostrar: `web config: API_URL=https://...`

---

## Site / `web` não sobe

1. Compose na `main` tem o serviço `web:`?
2. Package `church-app/web:latest` existe e está público?
3. `WEB_API_URL` está no Environment? (sem isso o container `web` **sai com erro**)
4. Domains → serviço **`web`**, porta **`80`**
5. Logs: `docker compose logs web`

---

## O que NÃO fazer

- Não ative build no Dokploy
- Não use `docker-compose.build.yml` na VPS
- Não aponte o domínio do site para o serviço `api`
- Não fixe `container_name` no compose (quebra 2+ deploys do mesmo código na mesma VPS)
- Não reutilize o mesmo `COMPOSE_PROJECT_NAME` em dois apps Dokploy
- Não coloque `postgres-db` na `dokploy-network` (alias DNS compartilhado)
