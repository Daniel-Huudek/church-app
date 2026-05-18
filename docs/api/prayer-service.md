# Prayer Service - Documentação da API

## Visão Geral
Serviço responsável por pedidos de oração, categorias, comentários, reações e intercessores.

**Base URL:** `http://localhost:3007` (interno) / `http://localhost:3000/prayers` (via Gateway)

**Autenticação:** Bearer Token (JWT)

---

## Endpoints

### Pedidos de Oração

#### `GET /prayers`
Feed de pedidos de oração públicos.

**Query Parameters:**
| Parâmetro | Tipo | Descrição |
|-----------|------|-----------|
| `page` | number | Página |
| `limit` | number | Limite |
| `categoryId` | uuid | Filtro por categoria |
| `isUrgent` | boolean | Apenas urgentes |

#### `GET /prayers/my`
Meus pedidos de oração.

#### `GET /prayers/urgent`
Pedidos urgentes.

#### `GET /prayers/favorites`
Pedidos favoritados.

#### `GET /prayers/:id`
Detalhe do pedido.

#### `POST /prayers`
Cria novo pedido.

**Body:**
```json
{
  "title": "Pedido de oração",
  "content": "Estou passando por um momento difícil...",
  "categoryId": "uuid",
  "isPublic": true,
  "isAnonymous": false,
  "isUrgent": false
}
```

#### `PUT /prayers/:id`
Atualiza pedido.

#### `DELETE /prayers/:id`
Soft delete do pedido.

#### `POST /prayers/:id/answer`
Marca como atendido.

#### `POST /prayers/:id/comments`
Adiciona comentário.

**Body:** `{ "content": "Estou orando por você!" }`

#### `POST /prayers/:id/react`
Reage ao pedido.

**Body:** `{ "type": "AMEN" }` (Tipos: PRAYING, AMEN, THANKS)

#### `POST /prayers/:id/intercede`
Oferece-se como intercessor.

#### `GET /prayers/:id/intercessors`
Lista intercessores.

#### `POST /prayers/:id/favorite`
Favorita/desfavorita pedido.

### Categorias

#### `GET /prayers/categories`
Lista categorias.

#### `POST /prayers/categories`
Cria categoria.

**Body:** `{ "name": "Saúde", "color": "#ff4444", "icon": "heart" }`
