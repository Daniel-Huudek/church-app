# Church App — Estrutura do Projeto

## Stack

- **Runtime:** Node.js 22
- **Package manager:** pnpm 10.12 (workspaces)
- **Backend:** Fastify v4 + TypeScript (monólito modular)
- **ORM:** Prisma (PostgreSQL — banco único `church_db`)
- **Validação:** Zod
- **Auth:** JWT (jsonwebtoken + @fastify/jwt) + bcryptjs + Google OAuth
- **Mobile:** Flutter 3.5+ (Riverpod + GoRouter + Dio)
- **Web:** Vite + React + TypeScript (`apps/web` — site público IPI Avaré)
- **Infra:** Docker Compose + Traefik + PostgreSQL 16

## Monorepo Structure

```
church-app/
├── apps/                          # Backend + Mobile + Web
│   ├── api/                       # Monólito modular (porta 3030)
│   │   ├── prisma/                # Schema unificado + migrations
│   │   └── src/modules/           # Domínios: auth, members, events, …
│   ├── flutter/                   # App mobile (Dart/Flutter)
│   └── web/                       # Site público IPI Avaré (porta 5173)
├── packages/                      # Pacotes compartilhados
│   ├── shared/   -> @church-app/shared    # errors, logger, validation, http-client, rbac
│   ├── tsconfig/ -> @church-app/tsconfig  # Base TS config (estendida por todos)
│   └── eslint-config/ -> @church-app/eslint-config  # ESLint config
├── docker/
│   ├── Dockerfile.service         # Imagem multi-stage compartilhada
│   ├── start-service.sh           # Entrypoint de produção
│   └── postgres/init.sql          # Init do Postgres
├── docker-bake.hcl                # Build (buildx bake)
├── docker-compose.yml             # api + postgres
└── .github/workflows/ci.yml       # CI: lint, test, build, security-audit, docker-build
```

## API modular (`apps/api`)

```
apps/api/
├── prisma/schema.prisma           # Schema único (todos os domínios)
├── src/
│   ├── index.ts                   # Bootstrap Fastify + Prisma + JWT
│   ├── routes/                    # Adaptadores públicos (ex: /users)
│   └── modules/                   # Domínios
│       ├── auth/
│       ├── members/
│       ├── schedules/
│       ├── events/
│       ├── notifications/
│       ├── prayers/
│       ├── finance/
│       ├── worship/
│       └── chat/
├── start.sh                       # prisma migrate deploy + node dist/index.js
└── package.json
```

Imagem Docker: `docker/Dockerfile.service` (args `SERVICE=api` / `PORT=3030` / `PACKAGE_NAME=@church-app/api` / `HAS_PRISMA=true`).

## Regras para edição

### Imports
- **SEMPRE** importar de `@church-app/shared`, NUNCA criar `src/shared/` local
- `import { AppError, logger, validate } from '@church-app/shared';`

### Container
- **Dokploy / VPS 4GB:** nunca buildar na VPS — ver `docs/deploy-dokploy.md`
- Imagem: `ghcr.io/daniel-huudek/church-app/api` via `.github/workflows/docker-publish.yml`
- `docker-compose.yml` **sem** `build:` (só `image:` + `pull_policy: always`)
- Build opcional no PC: `docker-compose.build.yml` + `./scripts/docker-build-push-pc.sh`
- Dockerfile multi-stage: `docker/Dockerfile.service`
- Runtime: bundle esbuild + `node dist/index.js`; migrations via `prisma migrate deploy`
- Heap ~192MB; `mem_limit: 320m` para a API

### Banco de Dados
- Um PostgreSQL (`church_db`) com schema Prisma unificado
- Schema versionado com Prisma Migrate (`prisma migrate dev` / `prisma migrate deploy`)
- Soft delete com `deletedAt: DateTime?` e filtro `where: { deletedAt: null }`
- **SEMPRE** adicionar `@@index([foreignKey])` em campos de relacionamento

### Autenticação
- JWT via `@fastify/jwt` + `authenticate()` / `authorize()` de `@church-app/shared`
- RBAC no módulo finance usa `authorize()` / `assertFinanceWriteRole`

### Rotas
- API expõe: `/auth/*`, `/members/*`, `/events/*`, `/schedules/*`, `/notifications/*`, `/prayers/*`, `/finance/*`, `/users/*`, `/worship/*`, `/chats/*`
- Health: `GET /health`
- Website CMS: `GET /website` (público), `PUT /website` (ADMINISTRADOR/PASTOR)

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
- API config em `lib/core/config/api_config.dart` (`API_URL` → porta 3030)
- Modelos em `lib/shared/models/` (UserModel, MemberModel, etc.)
