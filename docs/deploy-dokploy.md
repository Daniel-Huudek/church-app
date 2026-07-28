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

Serviços no `docker-compose.yml`: **`api` + `web` + `postgres-db`**.

---

## Passo 1 — Merge e publicar imagens

1. Mergeie o PR deste fluxo na `main`
2. GitHub → **Actions** → **Docker Publish** → **Run workflow**
3. Espere ficar verde (publica `api` e `web`)

Confirme o package do site:  
https://github.com/users/Daniel-Huudek/packages/container/package/church-app%2Fweb

(Alternativa no PC: `./scripts/docker-build-push-pc.sh` — ver `docs/deploy-pc-vps.md`)

## Passo 2 — Packages públicos (uma vez)

1. GitHub → **Packages**
2. Para cada pacote (`church-app/api` e `church-app/web`):
   **Package settings** → **Change visibility** → **Public**

Se ficar privado, o Dokploy precisa de login GHCR (`read:packages`).

## Passo 3 — Configurar o Dokploy

1. Aplicação tipo **Docker Compose** (não Stack)
2. **Compose file:** `docker-compose.yml` (sem `build:`)
3. Branch: `main` — faça **pull/reload** do repositório após mudanças no compose
4. **Desative** “Build on deploy”
5. Variáveis (`.env.example`):
   - `POSTGRES_USER`, `POSTGRES_PASSWORD`
   - `JWT_SECRET` (**obrigatório**)
   - `CORS_ORIGIN=https://ipiavare.com.br,https://www.ipiavare.com.br`
   - `WEB_API_URL=https://api.ipiavare.com.br`
   - opcional: Google, Evolution, YouTube, AWS, `IMAGE_TAG=latest`
6. Aba **Domains** (recomendado pelo Dokploy):
   - Domínio da API → serviço **`api`** → porta **`3030`**
   - Domínio do site → serviço **`web`** → porta **`80`**
7. **Deploy / Redeploy**

O compose já inclui a rede externa `dokploy-network` (Traefik) em `api`, `web` e `postgres-db`.

### Conferência rápida

| Serviço        | Imagem GHCR                         | Porta interna | Host publish |
|----------------|-------------------------------------|---------------|--------------|
| `api`          | `.../church-app/api`                | 3030          | 3030         |
| `web`          | `.../church-app/web`                | 80            | 8088         |
| `postgres-db`  | `postgres:16-alpine`                | 5432          | —            |

Teste sem domínio: `http://IP-DA-VPS:8088` (site) e `:3030/health` (API).

## Passo 4 — Dia a dia

1. Push na `main` → Actions publica `api` e `web`
2. Dokploy → **Redeploy** (só pull)

---

## Site / container `web` não aparece

1. **Imagem publicada?** Package `church-app/web` com tag `latest` (após o fix do Docker Publish).
2. **Compose atualizado?** No Dokploy, o YAML precisa ter o serviço `web:`. Use **Preview Compose** / reload do git na `main`.
3. **Redeploy** depois que a imagem `web` existir (se o deploy foi feito quando o publish do web ainda falhava, o pull pode ter falhado).
4. **Logs do deploy** no Dokploy — procure `church-app/web` / `pull` / `denied` / `not found`.
5. No servidor:
   ```bash
   docker ps -a | grep -E 'web|church-app'
   docker compose -f docker-compose.yml ps
   docker compose -f docker-compose.yml logs web --tail=100
   ```
6. **Domínio:** aba Domains → serviço **`web`**, porta **`80`** (não a porta 8088).
7. Se o package estiver privado: registry `ghcr.io` + token `read:packages`.

---

## Migração a partir dos microserviços

Esta versão usa **um** banco `church_db` e as imagens `church-app/api` + `church-app/web`.  
Em ambientes novos (volume Postgres limpo), o `prisma migrate deploy` cria o schema.

---

## Se der erro de pull (GHCR privado)

- Registry: `ghcr.io`
- User: seu usuário GitHub
- Password: token com `read:packages`

---

## O que NÃO fazer

- Não ative build no Dokploy
- Não rode `docker compose build` na VPS
- Não use `docker-compose.build.yml` na VPS (só PC/CI)
- Não aponte o domínio do site para o serviço `api`
