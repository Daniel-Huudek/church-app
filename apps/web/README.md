# @church-app/web — Site da Primeira IPI Avaré

Site institucional público da **Primeira Igreja Presbiteriana Independente de Avaré**.

## Conteúdo

- Hero com marca (logo farol / IPI Avaré)
- Horários de culto
- Sobre a igreja
- Ministérios
- Como visitar (endereço, telefone, e-mail, mapa)

Dados editáveis em `src/data/church.ts`.

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

Saída estática em `apps/web/dist` — pode ser servida por Nginx, Cloudflare Pages, Vercel, etc.
