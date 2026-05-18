# Member Service - Documentação da API

## Visão Geral
Serviço responsável pelo cadastro completo de membros da igreja, incluindo perfil, endereço, documentos, família, histórico ministerial, batismo, cargos e ministérios.

**Base URL:** `http://localhost:3006` (interno) / `http://localhost:3000/members` (via Gateway)

**Autenticação:** Bearer Token (JWT)

---

## Endpoints

### Membros

#### `GET /members`
Lista todos os membros com paginação e filtros.

**Query Parameters:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `page` | number | Número da página (default: 1) |
| `limit` | number | Itens por página (default: 20, max: 100) |
| `name` | string | Filtro por nome |
| `email` | string | Filtro por email |
| `status` | enum | ATIVO, INATIVO, AFASTADO, TRANSFERIDO, EXCLUIDO |
| `role` | enum | MEMBRO, DIACONO, PRESBITERO, PASTOR |
| `ministryId` | uuid | Filtro por ministério |
| `birthdayMonth` | number | Filtro por mês de aniversário (1-12) |

**Response:**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": "uuid",
        "name": "João Silva",
        "email": "joao@email.com",
        "phone": "(11) 99999-9999",
        "status": "ATIVO",
        "role": "MEMBRO",
        "isBaptized": true,
        "ministry": { "id": "uuid", "name": "Louvor" },
        "createdAt": "2024-01-01T00:00:00.000Z"
      }
    ],
    "total": 50,
    "page": 1,
    "limit": 20,
    "totalPages": 3
  }
}
```

#### `GET /members/search`
Busca avançada por membros.

**Query Parameters:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `q` | string | Termo de busca (nome, email, telefone, cargo) |
| `page` | number | Página |
| `limit` | number | Limite |

#### `GET /members/export`
Exporta lista de membros em formato JSON/CSV.

#### `POST /members/import`
Importa membros em lote via CSV.

**Body:**
```json
{
  "records": [
    { "name": "Maria", "email": "maria@email.com", "phone": "(11) 98888-8888" }
  ]
}
```

#### `GET /members/:id`
Retorna perfil completo do membro.

**Response inclui:** address, documents, familyMembers, ministerialHistory

#### `POST /members`
Cria um novo membro.

**Body:**
```json
{
  "name": "João Silva",
  "email": "joao@email.com",
  "phone": "(11) 99999-9999",
  "dateOfBirth": "1990-05-15",
  "gender": "MASCULINO",
  "maritalStatus": "CASADO",
  "isBaptized": true,
  "baptismDate": "2010-03-20",
  "status": "ATIVO",
  "role": "MEMBRO",
  "ministryId": "uuid"
}
```

#### `PUT /members/:id`
Atualiza dados do membro.

#### `DELETE /members/:id`
Soft delete do membro.

#### `GET /members/user/:userId`
Busca membro pelo ID do usuário (auth).

#### `GET /members/:id/address`
Retorna endereço do membro.

#### `PUT /members/:id/address`
Cria ou atualiza endereço.

**Body:**
```json
{
  "street": "Rua das Flores",
  "number": "123",
  "neighborhood": "Centro",
  "city": "São Paulo",
  "state": "SP",
  "zipCode": "01001-000"
}
```

#### `GET /members/:id/documents`
Lista documentos do membro.

#### `POST /members/:id/documents`
Adiciona documento.

**Body:** `{ "type": "RG", "value": "12.345.678-9" }`

#### `DELETE /members/:id/documents/:docId`
Remove documento.

#### `GET /members/:id/family`
Lista familiares.

#### `POST /members/:id/family`
Adiciona familiar.

**Body:** `{ "name": "Ana", "kinship": "CONJUGE", "phone": "(11) 97777-7777" }`

#### `DELETE /members/:id/family/:familyId`
Remove familiar.

#### `GET /members/:id/history`
Histórico ministerial.

#### `POST /members/:id/history`
Adiciona histórico.

**Body:**
```json
{
  "ministry": "Louvor",
  "role": "Vocal",
  "startDate": "2020-01-01",
  "endDate": "2023-12-31",
  "description": "Serviu como vocalista"
}
```

#### `POST /members/:id/photo`
Upload de foto do membro (multipart/form-data).

#### `GET /members/:id/audit`
Logs de auditoria do membro.

---

### Ministérios

#### `GET /ministries`
Lista ministérios.

#### `POST /ministries`
Cria ministério.

**Body:** `{ "name": "Louvor", "description": "Ministério de música", "leaderId": "uuid" }`

#### `PUT /ministries/:id`
Atualiza ministério.

#### `DELETE /ministries/:id`
Remove ministério (soft delete).
