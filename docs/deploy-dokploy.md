# Deploy com Dokploy (recomendado)

## Ideia

**Boa prática:** a VPS **nunca builda**.  
GitHub Actions (ou seu PC) gera as imagens → publica no GHCR → Dokploy só **puxa e sobe**.

```
Seu código (git push)
        │
        ▼
GitHub Actions "Docker Publish"
        │
        ▼
ghcr.io/daniel-huudek/church-app/api:latest
ghcr.io/daniel-huudek/church-app/web:latest
        │
        ▼
Dokploy na VPS  →  pull  →  docker compose up
```

A VPS de 4GB fica leve com **API + site estático (nginx) + Postgres**.

---

## Passo 1 — Merge e publicar imagens

1. Mergeie o PR deste fluxo na `main`
2. GitHub → **Actions** → **Docker Publish** → **Run workflow**
3. Espere ficar verde (publica `api` e `web`)

(Alternativa no PC: `./scripts/docker-build-push-pc.sh` — ver `docs/deploy-pc-vps.md`)

## Passo 2 — Packages públicos (uma vez)

1. GitHub → **Packages**
2. Para cada pacote (`church-app/api` e `church-app/web`):
   **Package settings** → **Change visibility** → **Public**

Se ficar privado, o Dokploy precisa de login GHCR (`read:packages`).

## Passo 3 — Configurar o Dokploy

1. Crie/edite a aplicação **Docker Compose**
2. **Compose file:** só `docker-compose.yml`  
   (este arquivo **não tem** seção `build:` — não tem como buildar por engano)
3. **Desative** qualquer opção de “Build on deploy” / “Build image”
4. Variáveis de ambiente (iguais ao `.env.example`):
   - `POSTGRES_USER`, `POSTGRES_PASSWORD`
   - `JWT_SECRET` (**obrigatório**)
   - `CORS_ORIGIN` — inclua a origem do site, ex.:  
     `https://ipiavare.com.br,https://www.ipiavare.com.br`
   - `WEB_API_URL=https://api.ipiavare.com.br` (URL pública da API no browser)
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (se usar Google)
   - opcional: `EVOLUTION_API_*`, `YOUTUBE_API_KEY`, `AWS_*`, `IMAGE_TAG=latest`
5. Deploy / Redeploy

O Dokploy deve fazer basicamente:
```bash
docker compose pull
docker compose up -d
```

### Domínios (Traefik)

| Serviço | Host (labels no compose) | Porta container |
|---------|--------------------------|-----------------|
| `api`   | `api.ipiavare.com.br`    | 3030            |
| `web`   | `ipiavare.com.br` + `www` | 80             |

Ajuste os labels Traefik no `docker-compose.yml` se o domínio for outro.

O container `web` gera `/config.js` no start com `WEB_API_URL`, para o site chamar a API correta sem rebuild.

## Passo 4 — Dia a dia

1. Você faz commit + push na `main`
2. Actions publica as imagens `api` e `web`
3. No Dokploy: **Redeploy** (pull das imagens novas)

Não precisa buildar na VPS.

---

## Migração a partir dos microserviços

Esta versão usa **um** banco `church_db` e as imagens `church-app/api` + `church-app/web`.  
Em ambientes novos (volume Postgres limpo), o `prisma migrate deploy` cria o schema.  
Se ainda tiver os DBs antigos (`auth_db`, `member_db`, …), faça backup e reimporte para `church_db` (ou suba com volume novo em staging primeiro).

---

## Se der erro de pull (GHCR privado)

No servidor / Dokploy, configure registry login:
- Registry: `ghcr.io`
- User: seu usuário GitHub
- Password: token com `read:packages`

---

## O que NÃO fazer

- Não ative build no Dokploy
- Não rode `docker compose build` na VPS
- Não use `docker-compose.build.yml` na VPS (esse arquivo é só PC/CI)
