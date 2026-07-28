# Church App - Sistema de Gerenciamento para Igrejas

Plataforma completa de gerenciamento para igrejas com arquitetura de microserviços e app Flutter.

## Stack

### Backend
- Node.js 22 + TypeScript
- Fastify
- Prisma ORM
- PostgreSQL 16
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
  /api-gateway          - Gateway central (porta 3030)
  /auth-service         - Autenticação (porta 3001)
  /chat-service         - Chat (porta 3002)
  /schedule-service     - Escalas (porta 3003)
  /event-service        - Eventos (porta 3004)
  /notification-service - WhatsApp/Evolution API (porta 3005)
  /member-service       - Membros e ministérios (porta 3006)
  /prayer-service       - Pedidos de oração (porta 3007)
  /financial-service    - Gestão financeira (porta 3008)
  /worship-service      - Louvor/músicas (porta 3010)
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

# Rodar todos os serviços em modo desenvolvimento
pnpm dev

# Build
pnpm build

# Docker
docker-compose up -d
```

## Serviços

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| API Gateway | 3030 | Roteamento, auth JWT, RBAC |
| Auth Service | 3001 | Login, OAuth Google |
| Chat Service | 3002 | Salas e mensagens |
| Schedule Service | 3003 | Escalas, confirmações |
| Event Service | 3004 | Eventos, calendário |
| Notification Service | 3005 | WhatsApp/Evolution API |
| Member Service | 3006 | Membros, ministérios, perfis |
| Prayer Service | 3007 | Pedidos de oração |
| Financial Service | 3008 | Gestão financeira com RBAC |
| Worship Service | 3010 | Músicas, playlists, escalas de louvor |

## Deploy

**Dokploy (VPS 4GB):** não buildar no servidor. Ver `docs/deploy-dokploy.md`.

1. GitHub Actions publica imagens no GHCR  
2. Dokploy só faz pull + up (`docker-compose.yml`)

Build opcional no PC: `./scripts/docker-build-push-pc.sh`
