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
ghcr.io/daniel-huudek/church-app/<serviço>:latest
        │
        ▼
Dokploy na VPS  →  pull  →  docker compose up
```

A VPS de 4GB já usa ~1.2GB. Build local nela **trava**.

---

## Passo 1 — Merge e publicar imagens

1. Mergeie o PR deste fluxo na `main`
2. GitHub → **Actions** → **Docker Publish** → **Run workflow**
3. Espere ficar verde

(Alternativa no PC: `./scripts/docker-build-push-pc.sh` — ver `docs/deploy-pc-vps.md`)

## Passo 2 — Packages públicos (uma vez)

1. GitHub → **Packages**
2. Para cada `church-app/...` → **Package settings** → **Change visibility** → **Public**

Se ficar privado, o Dokploy precisa de login GHCR (`read:packages`).

## Passo 3 — Configurar o Dokploy

1. Crie/edite a aplicação **Docker Compose**
2. **Compose file:** só `docker-compose.yml`  
   (este arquivo **não tem** seção `build:` — não tem como buildar por engano)
3. **Desative** qualquer opção de “Build on deploy” / “Build image”
4. Variáveis de ambiente (iguais ao `.env.example`):
   - `POSTGRES_USER`, `POSTGRES_PASSWORD`
   - `JWT_SECRET` (**obrigatório**)
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (se usar Google)
   - opcional: `IMAGE_TAG=latest`
5. Deploy / Redeploy

O Dokploy deve fazer basicamente:
```bash
docker compose pull
docker compose up -d
```

## Passo 4 — Dia a dia

1. Você faz commit + push na `main`
2. Actions publica imagens novas
3. No Dokploy: **Redeploy** (pull das imagens novas)

Não precisa buildar na VPS.

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
