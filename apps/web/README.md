# @church-app/web — Site da Primeira IPI Avaré

Site institucional público baseado no layout Figma da **IPI Avaré**.

## Seções / páginas

- `/` — Home (banner, eventos, palavra, notícias, transmissões)
- `/afirmacao-de-fe` — Afirmação de Fé da IPI do Brasil
- `/lideranca` — Nossa Liderança

Header com dropdowns (Nossa Igreja, O que cremos, IPI Comunica) e footer com barra azul.

Dados editáveis em `src/data/church.ts`. Foto do pastor em `public/pastor.jpg`.

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
