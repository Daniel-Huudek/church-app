# Deploy — build no PC (opcional)

Use isto **só se não quiser esperar o GitHub Actions**.  
No Dokploy / VPS o fluxo oficial é: `docs/deploy-dokploy.md`.

## No PC

```bash
export GHCR_USER=seu-usuario-github
export GHCR_TOKEN=ghp_xxx   # write:packages + read:packages

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

./scripts/docker-build-push-pc.sh
# (builda e publica api + web no GHCR)
# Só um serviço: ./scripts/docker-build-push-pc.sh web
```

Depois: packages **Public** no GitHub (`church-app/api` e `church-app/web`) → no Dokploy clique **Redeploy**.

## Na VPS

Nunca buildar. Só:
```bash
./scripts/docker-deploy-vps.sh
```
