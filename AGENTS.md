# Church App — Estrutura do Projeto

## Stack

- **Runtime:** Node.js 22
- **Package manager:** pnpm 11 (workspaces)
- **Backend:** Fastify v4 + TypeScript
- **ORM:** Prisma (PostgreSQL — banco por serviço)
- **Validação:** Zod
- **Auth:** JWT (jsonwebtoken + @fastify/jwt) + bcryptjs + Google OAuth
- **Mobile:** Flutter 3.5+ (Riverpod + GoRouter + Dio)
- **Infra:** Docker Compose + Traefik + PostgreSQL 16

## Monorepo Structure

```
church-app/
├── apps/                          # Microserviços + Mobile
│   ├── api-gateway/               # Proxy reverso (porta 3030)
│   ├── auth-service/              # Auth (porta 3001)
│   ├── member-service/            # Membros (porta 3006)
│   ├── event-service/             # Eventos (porta 3004)
│   ├── schedule-service/          # Escalas (porta 3003)
│   ├── notification-service/      # Notificações WhatsApp (porta 3005)
│   ├── prayer-service/            # Pedidos de oração (porta 3007)
│   ├── financial-service/         # Finanças (porta 3008)
│   └── flutter/                   # App mobile (Dart/Flutter)
├── packages/                      # Pacotes compartilhados
│   ├── shared/   -> @church-app/shared    # errors, logger, validation, http-client, rbac
│   ├── types/    -> @church-app/types     # Tipos de domínio (User, Member, Event, etc.)
│   ├── tsconfig/ -> @church-app/tsconfig  # Base TS config (estendida por todos)
│   └── eslint-config/ -> @church-app/eslint-config  # ESLint config
├── docker/
│   └── postgres/init.sql          # Cria 7 databases no startup
├── docker-compose.yml             # 9 serviços (8 apps + postgres)
└── .github/workflows/ci.yml       # CI: lint, test, build, security-audit, docker-build
```

## Microserviços (apps/*/)

Cada serviço segue o mesmo padrão:

```
apps/<service>/
├── prisma/schema.prisma           # Schema do banco (banco próprio)
├── src/
│   ├── index.ts                   # Bootstrap Fastify + Prisma
│   ├── routes/                    # Rotas Fastify
│   ├── services/                  # Lógica de negócio
│   └── shared/                    # (removido — agora usa @church-app/shared)
├── Dockerfile                     # node:22-alpine
├── start.sh                       # prisma migrate deploy + tsx src/index.ts
└── package.json                   # dependências + scripts dev/build/lint/test
```

## Regras para edição

### Imports
- **SEMPRE** importar de `@church-app/shared` e `@church-app/types`, NUNCA criar `src/shared/` local
- `import { AppError, logger, validate } from '@church-app/shared';`
- `import { User, Member, Event } from '@church-app/types';`

### Container
- O WORKDIR final é `/app/apps/<service>` em todos os Dockerfiles
- SEMPRE usar `USER node` antes do `CMD`
- `RUN chown -R node:node /app` antes de `USER node`

### Banco de Dados
- Cada serviço tem seu próprio banco PostgreSQL (ex: `auth_db`, `member_db`, etc.)
- Schema versionado com Prisma Migrate (`prisma migrate dev` / `prisma migrate deploy`)
- Soft delete com `deletedAt: DateTime?` e filtro `where: { deletedAt: null }`
- **SEMPRE** adicionar `@@index([foreignKey])` em campos de relacionamento

### Autenticação
- JWT via `@fastify/jwt` no API Gateway
- RBAC no financial-service usa middleware `authorize()` de `@church-app/shared`
- Nenhum serviço interno (auth, member, event, schedule, notification, prayer) tem auth própria (confiam na rede interna)

### Rotas
- API Gateway expõe: `/auth/*`, `/members/*`, `/events/*`, `/schedules/*`, `/notifications/*`, `/prayers/*`, `/finance/*`, `/users/*`
- Cada serviço expõe: `/health` + suas rotas com prefixo

### Padrões de código
- Fastify + async/await
- Zod para validação de input (schemas nas routes)
- Error handling: `AppError` (statusCode + message) lançado nos services, capturado no `setErrorHandler`
- Retorno: `{ success: true, data }` ou `{ success: false, message }`

### CI/CD
- Workflow em `.github/workflows/ci.yml`
- Jobs: lint → test → build → security-audit → docker-build
- Pnpm cache habilitado via `actions/setup-node`
- Segurança: `pnpm audit --audit-level=high` + Gitleaks

### Mobile (Flutter)
- `apps/flutter/` — feature-first architecture
- Riverpod para estado, GoRouter para navegação, Dio para HTTP
- Auth interceptor com refresh automático de token
- Google Sign-In como método de login
- API config em `lib/core/config/api_config.dart`
- Modelos em `lib/shared/models/` (UserModel, MemberModel, etc.)

## Cursor Cloud specific instructions

The update script runs `pnpm install` + builds `@church-app/shared` (its `dist/` is
imported at runtime via tsx, so it must be built before any service starts).
PostgreSQL 16, the `church`/`church123` superuser role, and the 9 databases persist
in the VM snapshot — they are not re-created by the update script.

### Serviços
9 microserviços Fastify + `api-gateway` (todos em dev via `tsx`), cada um com seu
próprio banco PostgreSQL, mais o app Flutter (`apps/flutter`). Portas: auth 3001,
chat 3002, schedule 3003, event 3004, notification 3005, member 3006, prayer 3007,
financial 3008, worship 3010, gateway 3030.

### Iniciar o backend (dev)
- Postgres não sobe sozinho: `sudo pg_ctlcluster 16 main start` (dados/DBs já existem).
- Não use `pnpm dev` (paralelo) para o stack completo. Dois motivos não-óbvios:
  1. Nenhum serviço carrega dotenv — leem `process.env` direto, então cada serviço
     precisa do seu próprio `DATABASE_URL`/`PORT` exportado (impossível num único env
     compartilhado).
  2. Todos os serviços compartilham UM `@prisma/client` (hoisting pnpm); cada
     `prisma generate` sobrescreve o anterior. É preciso gerar o client de cada
     serviço imediatamente antes de iniciá-lo e carregá-lo em memória usando `tsx`
     (sem `watch`, para um generate posterior não recarregar o processo com o client
     errado).
- Use o launcher pronto que codifica isso: `bash scripts/dev-start-backend.sh`
  (gera+inicia em sequência, espera `/health` e escreve logs em `/tmp/logs/`).
- Schema por serviço: em banco novo rode `prisma db push` em cada `apps/<svc>`
  (os scripts `dev` NÃO migram; só `start.sh` roda `prisma db push`).

### Login / auth
- O login do app Flutter é **somente Google Sign-In** (não há formulário de e-mail/senha
  na UI). Entrar pela UI exige `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` + client web
  configurado. O backend expõe `POST /auth/register` e `POST /auth/login` por e-mail/senha
  — dá para exercitar auth de ponta a ponta via API pelo gateway (ex.: `/auth/register`,
  `/auth/login`, e rota protegida `/users`). Não existe `/auth/me` no gateway.

### Flutter web (para ver a UI)
- `cd apps/flutter && flutter pub get`
- `flutter run -d web-server --web-port 8085 --web-hostname 0.0.0.0 --dart-define=API_URL=http://localhost:3030`
  (porta 8085 já está no `CORS_ORIGIN` do launcher). Primeira carga compila sob demanda.

### Lint / test (estado do repo, não do ambiente)
- `pnpm -r lint`: `auth-service` tem erros de lint pré-existentes (variáveis não usadas).
- `pnpm -r test`: usa vitest, mas não há arquivos de teste, então sai com código != 0
  ("No test files found"). A infra de teste funciona.
