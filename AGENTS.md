# Church App — Estrutura do Projeto

## Stack

- **Runtime:** Node.js 22
- **Package manager:** pnpm 10.12 (workspaces)
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
│   ├── chat-service/              # Chat (porta 3002)
│   ├── worship-service/           # Louvor (porta 3010)
│   └── flutter/                   # App mobile (Dart/Flutter)
├── packages/                      # Pacotes compartilhados
│   ├── shared/   -> @church-app/shared    # errors, logger, validation, http-client, rbac
│   ├── tsconfig/ -> @church-app/tsconfig  # Base TS config (estendida por todos)
│   └── eslint-config/ -> @church-app/eslint-config  # ESLint config
├── docker/
│   ├── Dockerfile.service         # Imagem multi-stage compartilhada
│   ├── start-service.sh           # Entrypoint de produção
│   └── postgres/init.sql          # Cria databases no startup
├── docker-bake.hcl                # Build paralelo (buildx bake)
├── docker-compose.yml             # Microserviços + postgres
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
│   └── services/                  # Lógica de negócio
├── start.sh                       # prisma migrate deploy + node dist/index.js
└── package.json                   # dependências + scripts dev/build/lint/test
```

Imagem Docker compartilhada: `docker/Dockerfile.service` (multi-stage, args `SERVICE` / `PORT` / `PACKAGE_NAME` / `HAS_PRISMA`).
## Regras para edição

### Imports
- **SEMPRE** importar de `@church-app/shared` e `@church-app/types`, NUNCA criar `src/shared/` local
- `import { AppError, logger, validate } from '@church-app/shared';`
- `import { User, Member, Event } from '@church-app/types';`

### Container
- Imagem única multi-stage: `docker/Dockerfile.service` (args `SERVICE`, `PORT`, `PACKAGE_NAME`, `HAS_PRISMA`)
- **VPS ~4GB / Dokploy:** build **serial** — `pnpm docker:build:vps` ou `docker compose build --parallel 1` (nunca bake paralelo)
- Build: `pnpm docker:build` (serial) / `pnpm docker:bake` (só em máquina forte / CI)
- Runtime: bundle esbuild + `node dist/index.js`; migrations via `prisma migrate deploy`
- Heap: build `NODE_OPTIONS=--max-old-space-size=384`, runtime `64`; serviços `mem_limit: 96m`
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
