# Orthogonal API cheatsheet

Base URL: `https://api.orthogonal.com`  
Auth: `Authorization: Bearer $ORTHOGONAL_API_KEY`

## Discovery

### POST `/v1/search`

```json
{ "prompt": "enrich lead find email", "limit": 5 }
```

Returns APIs with `slug`, `endpoints[].path`, `price`, `verified`, `score`.

### POST `/v1/details`

Full parameter schema for one endpoint (use before first call when unsure).

### POST `/v1/integrate`

Ready-to-use code snippets for an endpoint.

### GET `/v1/list-endpoints`

Catalog listing of available APIs/endpoints.

## Execution

### POST `/v1/run`

```json
{
  "api": "apollo",
  "path": "/v1/people/match",
  "body": { "email": "ceo@stripe.com" },
  "query": {}
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `api` | yes | slug from search |
| `path` | yes | endpoint path from search |
| `body` | no | POST/PUT/PATCH payload |
| `query` | no | query string key/values |

Response (typical):

```json
{
  "success": true,
  "price": "0.03",
  "priceCents": 3,
  "data": {},
  "requestId": "run_…"
}
```

## Account

- Balance / usage: dashboard or `orth account`
- Credits are pay-per-call; no subscription required
- Free starter credits commonly offered on signup

## SDK (`@orth/sdk`)

```ts
import Orthogonal, { OrthogonalRunError } from "@orth/sdk"

const orth = new Orthogonal({ apiKey: process.env.ORTHOGONAL_API_KEY! })
await orth.run({ api, path, body?, query? })
// throws OrthogonalRunError on non-2xx
```

## CLI (`@orth/cli`)

```bash
orth search "<prompt>"
orth api [slug] [path]
orth run <slug> <path> --body '…' | -q k=v
orth account
orth --json …
```

## MCP

URL: `https://mcp.orthogonal.com`  
Tools: `search`, `get_details`, `quote`, `use`, `integrate`, `batch_use`, `batch_get_details`

## Errors

| HTTP | Code | Fix |
|------|------|-----|
| 401 | UNAUTHORIZED | API key |
| 402 | INSUFFICIENT_CREDITS | top up |
| 404 | NOT_FOUND | re-search slug/path |
| 429 | RATE_LIMITED | backoff |
| 5xx | UPSTREAM_ERROR | surface + optional retry |

## Docs

- https://docs.orthogonal.com/llms.txt
- https://docs.orthogonal.com/quickstart
- https://docs.orthogonal.com/api-reference/introduction
