# @church-app/web — Site da Primeira IPI Avaré

Site institucional público baseado no layout Figma da **IPI Avaré**.

## Seções

- Header (Nossa Igreja, O que somos, IPI Comunica, redes, Conectar)
- Banner da série + Eventos e Programações
- Palavra da semana
- Notícias IPI Avaré
- Nossas Transmissões
- Footer (links, contato, mapa)

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
