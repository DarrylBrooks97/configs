---
name: orthogonal
description: >
  Use Orthogonal (orthogonal.com) to discover, call, and pay for external APIs
  from agents — web search, scrape, lead/company enrichment, email find/verify,
  LinkedIn, social intel, and more. Trigger when the user needs live external
  data, enrichment, scraping, research, GTM/prospecting workflows, or wants to
  integrate @orth/sdk, orth CLI, or the Orthogonal MCP server.
---

# Orthogonal

Orthogonal is one integration for a catalog of paid tools: discover → call → pay per request. One API key, pooled provider credentials, metered credits.

Docs: https://docs.orthogonal.com · Catalog: https://orthogonal.com/discover · Dashboard: https://orthogonal.com/dashboard

## When to use

- Need **fresh external data** (search, scrape, enrichment) instead of model knowledge
- Build **GTM / research workflows** (leads, companies, emails, social)
- Integrate Orthogonal into app code (`@orth/sdk`), CLI (`orth`), or MCP

Prefer Orthogonal over inventing one-off provider SDKs when the capability is in the catalog.

## Auth

```bash
export ORTHOGONAL_API_KEY=orth_live_xxxxxxxxxxxx
```

- Live keys: `orth_live_…` (billed)
- Test keys: `orth_test_…` (limited, no charge)
- Get keys: https://orthogonal.com/dashboard/settings/api-keys
- Never commit keys; never log full keys

If the key is missing, stop and ask the user to set `ORTHOGONAL_API_KEY` (or connect MCP).

## Connection options (pick one)

### 1. MCP (best for chat agents)

```json
{
  "mcpServers": {
    "orthogonal": {
      "url": "https://mcp.orthogonal.com"
    }
  }
}
```

MCP tools: `search`, `get_details`, `quote`, `use`, `integrate`, `batch_use`, `batch_get_details`.

Workflow: `search` → `get_details` / `quote` → `use` (or `batch_use`).

### 2. CLI

```bash
npm install -g @orth/cli
export ORTHOGONAL_API_KEY=orth_live_your_key

orth search "enrich lead find email"
orth api                              # list APIs
orth api apollo                       # endpoints for one API
orth api apollo /v1/people/match      # params + example
orth run apollo /v1/people/match --body '{"email":"ceo@stripe.com"}'
orth account                          # balance / usage
```

Flags: `--json`, `--key <key>`, `-q key=value` for query params.

### 3. HTTP API

Base: `https://api.orthogonal.com`  
Header: `Authorization: Bearer $ORTHOGONAL_API_KEY`

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/search` | Natural-language API discovery |
| POST | `/v1/details` | Endpoint parameter schema |
| POST | `/v1/integrate` | Code snippets |
| GET | `/v1/list-endpoints` | Full catalog listing |
| POST | `/v1/run` | Execute a call |

### 4. TypeScript SDK

```bash
pnpm add @orth/sdk
```

```typescript
import Orthogonal, { OrthogonalRunError } from "@orth/sdk";

const orth = new Orthogonal({ apiKey: process.env.ORTHOGONAL_API_KEY! });

const res = await orth.run({
  api: "tavily",
  path: "/search",
  query: { query: "latest AI news" },
});
// res.data, res.price, res.success

try {
  await orth.run({ api: "apollo", path: "/v1/people/match", body: { email: "a@b.com" } });
} catch (err) {
  if (err instanceof OrthogonalRunError) {
    // err.status, err.orthogonal (self-correct hint), err.responseBody
  }
}
```

## Canonical agent loop

1. **Discover** — search by intent; prefer `verified: true` and higher `score`.
2. **Inspect** — `details` / `orth api <slug> <path>` before guessing body fields.
3. **Quote** (optional) — price without spending when cost-sensitive.
4. **Run** — pass `api` (slug) + `path` + `body` and/or `query`.
5. **Handle errors** — use structured hints to fix and retry once; on `402` stop and tell user to add credits.
6. **Report** — return useful data **and** cost (`price` / `priceCents`).

Never invent `api` slugs or paths. Always discover or list first unless the user already gave exact slug+path from a prior result.

## Search

```bash
curl -s -X POST 'https://api.orthogonal.com/v1/search' \
  -H "Authorization: Bearer $ORTHOGONAL_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"enrich lead find email","limit":5}'
```

Use `results[].slug` + `results[].endpoints[].path` with `/v1/run`.

## Run

```bash
curl -s -X POST 'https://api.orthogonal.com/v1/run' \
  -H "Authorization: Bearer $ORTHOGONAL_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "api": "apollo",
    "path": "/v1/people/match",
    "body": { "email": "ceo@stripe.com" }
  }'
```

Success shape (fields may vary slightly by surface):

```json
{
  "success": true,
  "price": "0.03",
  "priceCents": 3,
  "data": {},
  "requestId": "run_…"
}
```

HTTP method is chosen by Orthogonal from endpoint config — you only pass `api`, `path`, `body`, `query`.

## Error handling

| Code | Meaning | Action |
|------|---------|--------|
| 400 | Bad request | Fix body/query using details / `OrthogonalRunError.orthogonal` |
| 401 | Bad/missing key | Fix `ORTHOGONAL_API_KEY` |
| 402 | Insufficient credits | Stop; user tops up at dashboard |
| 404 | Unknown api/path | Re-search catalog |
| 5xx | Upstream | Surface message; optional single retry |

Spend carefully: enrichment and deep research can stack cost. Prefer one verified endpoint over spraying many providers. Batch only when the user wants breadth.

## High-value recipes

Exact paths can change — **search first** if a call 404s. Common patterns:

### Web search
```bash
orth run tavily /search --body '{"query":"latest AI agent frameworks","search_depth":"advanced","include_answer":true}'
# or
orth run linkup /v1/search --body '{"q":"Series A fintech 2026","depth":"standard"}'
```

### Scrape page → markdown
```bash
orth run olostep /v1/scrapes --body '{"url_to_scrape":"https://example.com/pricing","formats":["markdown"]}'
```

### Find + verify email
```bash
orth run hunter /v2/email-finder -q domain=stripe.com -q first_name=Patrick -q last_name=Collison
orth run tomba /v1/email-verifier -q email=hello@example.com
```

### Person enrich
```bash
orth run apollo /v1/people/match --body '{"email":"ceo@stripe.com"}'
```

### Lead research chain
1. `linkup` / `tavily` — company news & context  
2. `hunter` domain-search — contacts  
3. `apollo` people/match — enrich top contact  

### Competitor intel chain
1. Social posts (e.g. LinkedIn/X providers in catalog)  
2. Brand/assets by domain  
3. Scrape pricing/docs with `olostep`

### ABM / ICP prospecting
1. People search by natural language (e.g. Fiber-style profile search)  
2. Activity check on LinkedIn  
3. Email find (Tomba/Hunter) → optional verify  

See `references/workflows.md` for fuller chains.

## Effect-TS integration pattern

When the codebase uses Effect, wrap Orthogonal as a service (do not call `fetch` ad hoc in domain logic):

```typescript
import { Context, Effect, Layer, Data } from "effect"
import Orthogonal, { OrthogonalRunError } from "@orth/sdk"

export class OrthError extends Data.TaggedError("OrthError")<{
  readonly message: string
  readonly status?: number
  readonly cause?: unknown
}> {}

export class Orth extends Context.Tag("Orth")<
  Orth,
  {
    readonly run: (input: {
      api: string
      path: string
      body?: Record<string, unknown>
      query?: Record<string, unknown>
    }) => Effect.Effect<{ data: unknown; price: string }, OrthError>
    readonly search: (
      prompt: string,
      limit?: number
    ) => Effect.Effect<unknown, OrthError>
  }
>() {}

export const OrthLive = Layer.effect(
  Orth,
  Effect.gen(function* () {
    const apiKey = process.env.ORTHOGONAL_API_KEY
    if (!apiKey) {
      return yield* Effect.die(new Error("ORTHOGONAL_API_KEY is not set"))
    }
    const client = new Orthogonal({ apiKey })

    const run: Orth["Type"]["run"] = (input) =>
      Effect.tryPromise({
        try: () => client.run(input),
        catch: (cause) =>
          cause instanceof OrthogonalRunError
            ? new OrthError({
                message: cause.message,
                status: cause.status,
                cause: cause.orthogonal ?? cause.responseBody,
              })
            : new OrthError({ message: String(cause), cause }),
      }).pipe(Effect.map((res) => ({ data: res.data, price: String(res.price) })))

    const search: Orth["Type"]["search"] = (prompt, limit = 10) =>
      Effect.tryPromise({
        try: async () => {
          const res = await fetch("https://api.orthogonal.com/v1/search", {
            method: "POST",
            headers: {
              Authorization: `Bearer ${apiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ prompt, limit }),
          })
          if (!res.ok) throw new Error(`search failed: ${res.status}`)
          return res.json()
        },
        catch: (cause) => new OrthError({ message: String(cause), cause }),
      })

    return { run, search }
  })
)
```

Compose with `effect-best-practices`: tagged errors, `Effect.fn` for named methods, `Effect.Service` if you prefer the service class style, never log secrets.

## Cost & safety rules

- Confirm destructive or high-volume batches with the user first
- Prefer verified endpoints
- Surface `price` / `priceCents` after paid calls
- Do not scrape or enrich personal data beyond what the user requested
- Do not store API keys in repo files

## Quick decision guide

| Need | Start with |
|------|------------|
| General web Q&A / research | `tavily` or `linkup` search |
| Page → clean text | `olostep` scrapes |
| Email from name+domain | `hunter` email-finder |
| Email validity | `tomba` / `hunter` verifier |
| Person by email/LinkedIn | `apollo` people/match |
| Company by domain | search "company enrichment" |
| Unknown capability | `orth search "<intent>"` or MCP `search` |

## References

- `references/workflows.md` — multi-step GTM/research chains
- `references/api-cheatsheet.md` — endpoints and response fields
- Live docs index: https://docs.orthogonal.com/llms.txt
