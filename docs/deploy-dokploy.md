# Deploy com Dokploy (recomendado)

## Ideia

A VPS **nunca builda**. GitHub publica imagens no GHCR → Dokploy só **puxa e sobe**.

Serviços: **`api`** + **`web`** (site) + **`postgres-db`**.

- **Domínio:** só na aba **Domains** do Dokploy (não no compose)
- **URL da API no site:** variável de ambiente **`WEB_API_URL`**

```
Browser → domínio do site (Dokploy) → container `web` (nginx)
                │
                └─ config.js usa WEB_API_URL → chama a API pública
```

---

## Passo 1 — Imagens no GHCR

1. `main` com Docker Publish verde (`api` + `web`)
2. Packages **Public**: `church-app/api` e `church-app/web`

## Passo 2 — Compose no Dokploy

1. App tipo **Docker Compose**
2. Compose file: `docker-compose.yml`
3. Branch `main`, **sem** “Build on deploy”
4. Redeploy / Deploy

## Passo 3 — Environment (Dokploy)

Defina no painel (grava `.env` do compose):

```env
POSTGRES_USER=...
POSTGRES_PASSWORD=...
JWT_SECRET=...

# Origem(ns) do site (domínio que você vai criar na aba Domains)
CORS_ORIGIN=https://seu-dominio.com.br,https://www.seu-dominio.com.br

# URL pública da API (o browser do visitante chama isso)
WEB_API_URL=https://api.seu-dominio.com.br
```

No start do container `web`, `WEB_API_URL` vira `/config.js` → `window.__ENV__.API_URL`.

## Passo 4 — Domains (Dokploy)

Na aba **Domains**, adicione:

| Domínio              | Serviço | Porta |
|----------------------|---------|-------|
| `api.seu-dominio...` | `api`   | 3030  |
| `seu-dominio...`     | `web`   | 80    |
| `www.seu-dominio...` | `web`   | 80    |

O Dokploy injeta Traefik + TLS. **Não** é preciso label `Host(...)` no `docker-compose.yml`.

Depois: **Deploy** de novo se o domínio foi adicionado após o primeiro up.

---

## Conferência

| Serviço       | Imagem                         | Porta do container |
|---------------|--------------------------------|--------------------|
| `api`         | `.../church-app/api`           | 3030               |
| `web`         | `.../church-app/web`           | 80                 |
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
