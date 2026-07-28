# Church App - Sistema de Gerenciamento para Igrejas

Plataforma completa de gerenciamento para igrejas com **API monólito modular** e app Flutter.

## Stack

### Backend
- Node.js 22 + TypeScript
- Fastify (monólito modular por domínio)
- Prisma ORM
- PostgreSQL 16 (`church_db`)
- Docker + Docker Compose
- pnpm workspaces

### Mobile
- Flutter 3.5+
- Riverpod (estado)
- GoRouter (navegação)
- Dio (HTTP)
- Flutter Secure Storage + Google Sign-In

## Estrutura

```
/apps
  /api                  - API monólito modular (porta 3030)
    /src/modules        - Domínios: auth, members, events, schedules, …
  /flutter              - App mobile Flutter

/packages
  /shared           - Utilitários compartilhados (@church-app/shared)
  /eslint-config    - Configuração ESLint
  /tsconfig         - Configuração TypeScript
```

## Configuração

1. Copie `.env.example` para `.env`:
```bash
cp .env.example .env
```

2. Configure as variáveis de ambiente (`JWT_SECRET`, Google OAuth, Evolution API, etc.)

## Desenvolvimento

```bash
# Instalar dependências
pnpm install

# Build do pacote shared
pnpm --filter @church-app/shared build

# Gerar Prisma Client
pnpm --filter @church-app/api db:generate

# Rodar a API em modo desenvolvimento
pnpm --filter @church-app/api dev

# Build
pnpm build

# Docker
docker compose up -d
```

## API

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| API | 3030 | Auth JWT, membros, eventos, escalas, oração, finanças, louvor, chat, notificações |

Rotas públicas (compatíveis com o app Flutter): `/auth`, `/users`, `/members`, `/events`, `/schedules`, `/prayers`, `/finance`, `/worship`, `/chats`, `/notifications`.

## Deploy

Ver `docs/deploy-dokploy.md` (VPS 4GB — só pull de imagem, sem build na VPS).
