# @church-app/web — Site da Primeira IPI Avaré

Site institucional público baseado no layout Figma da **IPI Avaré**.

## Seções / páginas

- `/` — Home (banner, eventos, palavra, notícias, transmissões)
- `/afirmacao-de-fe` — Afirmação de Fé da IPI do Brasil
- `/lideranca` — Nossa Liderança

Header com dropdowns (Nossa Igreja, O que cremos, IPI Comunica) e footer com barra azul.

## Conteúdo (CMS)

O site lê `GET /website` da API. Administradores/pastores editam no app Flutter:

**Painel administrativo → Site**

Imagens (banner / liderança) sobem para **AWS S3** via `POST /website/uploads`.
Ver `docs/aws-s3-website-uploads.md`.

Fallback local em `src/data/church.ts` se a API estiver offline.

Variável opcional: `VITE_API_URL` (default `http://localhost:3030`).

## Desenvolvimento

```bash
pnpm --filter @church-app/web dev
```

Abre em `http://localhost:5173`.

## Build

```bash
pnpm --filter @church-app/web build
pnpm --filter @church-app/web preview
```
