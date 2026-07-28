# Deploy — build no PC, VPS só puxa

## Por quê

A VPS tem 4GB e já usa ~1.2GB. **Build na VPS trava a máquina.**

Fluxo certo:
1. **PC** (ou GitHub Actions) → build + push pro GHCR  
2. **VPS** → só `pull` + `up`

---

## No seu PC (primeira vez)

### 1. Requisitos
- Docker Desktop instalado e aberto  
- Git do projeto atualizado (`git pull`)  
- Token GitHub: [Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)  
  - Escopos: `write:packages`, `read:packages`  
  - (classic) ou fine-grained com permissão de packages no repo

### 2. Login no GHCR
```bash
export GHCR_USER=seu-usuario-github
export GHCR_TOKEN=ghp_seu_token

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
```

### 3. Build + push (todos os serviços)
Na pasta do projeto:
```bash
chmod +x scripts/docker-build-push-pc.sh
./scripts/docker-build-push-pc.sh
```

Ou com pnpm:
```bash
pnpm docker:build:pc
```

Só um serviço (ex.: auth):
```bash
./scripts/docker-build-push-pc.sh auth-service
```

Demora vários minutos na primeira vez. Nas próximas, o cache do Docker acelera.

### 4. Deixar os packages públicos (recomendado)
1. GitHub → seu perfil → **Packages**  
2. Clique em cada `church-app/...`  
3. **Package settings** → **Change visibility** → **Public**

Assim a VPS puxa sem token.

---

## Na VPS / Dokploy (sem build)

```bash
cd /caminho/do/projeto
git pull
./scripts/docker-deploy-vps.sh
```

No Dokploy:
- Compose files: `docker-compose.yml` **e** `docker-compose.prod.yml`  
- **Desative** “build on deploy”  
- Deploy = pull + up

---

## Alternativa sem PC

Merge na `main` → Actions → **Docker Publish** → Run workflow.  
O GitHub builda e publica; na VPS só rode `./scripts/docker-deploy-vps.sh`.
