# Financial Service - Documentação da API

## Visão Geral
Serviço responsável pelo controle financeiro da igreja: entradas, saídas, dízimos, ofertas, categorias, centros de custo, relatórios e auditoria.

**Base URL:** `http://localhost:3008` (interno) / `http://localhost:3000/finance` (via Gateway)

**Autenticação:** Bearer Token (JWT) + RBAC

---

## Controle de Acesso (RBAC)

| Role | Acesso |
|------|--------|
| **ADMINISTRADOR** | Acesso total (CRUD, relatórios, fechamento, auditoria, exportação) |
| **PASTOR** | Leitura + criar/editar transações, ver relatórios |
| **FINANCEIRO** | Gerenciamento completo (CRUD, fechamento, auditoria, exportação) |
| **LIDER** | Sem acesso |
| **MEMBRO** | Sem acesso |

---

## Endpoints

### Transações

#### `GET /finance/transactions`
Lista transações.

**Query Parameters:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `page` | number | Página |
| `limit` | number | Limite |
| `type` | enum | INCOME, EXPENSE, TITHE, OFFERING |
| `status` | enum | PENDING, CONFIRMED, CANCELLED |
| `categoryId` | uuid | Filtro por categoria |
| `costCenterId` | uuid | Filtro por centro de custo |
| `startDate` | date | Data inicial |
| `endDate` | date | Data final |
| `search` | string | Busca por descrição/observações |

**Acesso:** ADMINISTRADOR, PASTOR, FINANCEIRO

#### `GET /finance/transactions/:id`
Detalhe da transação.

#### `POST /finance/transactions`
Cria lançamento.

**Body:**
```json
{
  "type": "INCOME",
  "value": 1500.00,
  "description": "Dízimo do João",
  "date": "2024-01-15",
  "categoryId": "uuid",
  "costCenterId": "uuid",
  "paymentMethod": "PIX",
  "notes": "Dízimo referente a janeiro"
}
```

**Acesso:** ADMINISTRADOR, FINANCEIRO

#### `PUT /finance/transactions/:id`
Atualiza lançamento.

#### `DELETE /finance/transactions/:id`
Soft delete.

#### `POST /finance/transactions/:id/confirm`
Confirma transação (altera status para CONFIRMED).

#### `POST /finance/transactions/:id/cancel`
Cancela transação.

#### `POST /finance/transactions/:id/attachments`
Upload de anexo/comprovante.

#### `GET /finance/transactions/:id/audit`
Log de auditoria da transação.

### Dashboard

#### `GET /finance/dashboard`
Dashboard completo: saldo, entradas/saídas do mês, por categoria, histórico mensal.

**Acesso:** ADMINISTRADOR, PASTOR, FINANCEIRO

#### `GET /finance/dashboard/balance`
Saldo atual (entradas - saídas).

**Response:**
```json
{
  "success": true,
  "data": {
    "income": 50000.00,
    "expense": 35000.00,
    "balance": 15000.00
  }
}
```

#### `GET /finance/dashboard/cash-flow`
Fluxo de caixa histórico.

### Relatórios

#### `GET /finance/reports/monthly`
Relatório mensal.

**Query Parameters:** `year`, `month`

**Response:**
```json
{
  "success": true,
  "data": {
    "period": "2024-01",
    "income": 50000.00,
    "expense": 35000.00,
    "tithes": 15000.00,
    "offerings": 8000.00,
    "balance": 15000.00,
    "byCategory": [{ "category": "Dízimos", "value": 15000.00 }],
    "byCostCenter": [{ "center": "Manutenção", "value": 5000.00 }]
  }
}
```

### Categorias

#### `GET /finance/categories`
Lista categorias de transação.

#### `POST /finance/categories`
Cria categoria.

**Body:** `{ "name": "Dízimos", "type": "INCOME", "color": "#4caf50" }`

**Acesso:** ADMINISTRADOR, FINANCEIRO

#### `PUT /finance/categories/:id`
Atualiza categoria.

### Centros de Custo

#### `GET /finance/cost-centers`
Lista centros de custo.

#### `POST /finance/cost-centers`
Cria centro de custo.

**Body:** `{ "name": "Manutenção", "budget": 10000.00 }`

### Fechamento Mensal

#### `POST /finance/monthly-close`
Realiza fechamento mensal.

**Body:** `{ "referenceDate": "2024-01-01", "notes": "Fechamento de janeiro" }`

**Acesso:** ADMINISTRADOR, FINANCEIRO

#### `GET /finance/monthly-close`
Histórico de fechamentos.

### Auditoria

#### `GET /finance/audit`
Log completo de auditoria financeira.

**Acesso:** ADMINISTRADOR, FINANCEIRO
