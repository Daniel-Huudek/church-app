# Church App - Sistema de Gerenciamento de Escalas

Plataforma completa de gerenciamento de escalas para igrejas com arquitetura de microserviços.

## Stack

### Backend
- Node.js + TypeScript
- Fastify
- Prisma ORM
- PostgreSQL
- Docker + Docker Compose

### Mobile
- React Native + Expo
- React Navigation
- Zustand (state management)
- React Query

## Estrutura

```
/apps
  /api-gateway          - Gateway central (porta 3000)
  /auth-service         - Autenticação (porta 3001)
  /member-service       - Membros e ministérios (porta 3006)
  /schedule-service     - Escalas (porta 3003)
  /event-service        - Eventos (porta 3004)
  /notification-service - WhatsApp/Evolution API (porta 3005)
  /prayer-service       - Pedidos de oração (porta 3007)
  /financial-service    - Gestão financeira (porta 3008)
  /mobile               - App Expo

/packages
  /shared           - Utilitários compartilhados
  /types            - Tipos TypeScript
  /eslint-config    - Configuração ESLint
  /tsconfig         - Configuração TypeScript
```

## Configuração

1. Copie `.env.example` para `.env`:
```bash
cp .env.example .env
```

2. Configure as variáveis de ambiente (Google OAuth, Evolution API, etc.)

## Desenvolvimento

```bash
# Instalar dependências
pnpm install

# Rodar todos os serviços em modo desenvolvimento
pnpm dev

# Build
pnpm build

# Docker
docker-compose up -d
```

## Servicios

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| API Gateway | 3000 | Roteamento, auth JWT |
| Auth Service | 3001 | Login, OAuth Google |
| Schedule Service | 3003 | Escalas, confirmações |
| Event Service | 3004 | Eventos, calendário |
| Notification Service | 3005 | WhatsApp/Evolution API |
| Member Service | 3006 | Membros, ministérios, perfis |
| Prayer Service | 3007 | Pedidos de oração |
| Financial Service | 3008 | Gestão financeira com RBAC |

## Deploy

O projeto é compatível com Dokploy e VPS Linux via Docker Compose.