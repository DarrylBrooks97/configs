# Orthogonal workflows

Paths and slugs can change. If a call 404s, run `orth search` / MCP `search` and update.

Shared helper (Node):

```js
const ORTH_KEY = process.env.ORTHOGONAL_API_KEY
async function run(api, path, body, query) {
  const res = await fetch("https://api.orthogonal.com/v1/run", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${ORTH_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ api, path, body, query }),
  })
  return res.json()
}
```

## 1. Lead research & enrichment

**Intent:** company context + contacts + enrich top person  
**Typical tools:** LinkUp/Tavily → Hunter → Apollo

```bash
orth run linkup /search --body '{"q":"stripe company funding valuation news","depth":"standard"}'
orth run hunter /domain-search --body '{"domain":"stripe.com"}'
orth run apollo /v1/people/match --body '{"email":"<from previous>"}'
```

## 2. Find + verify a specific person email

```bash
orth run hunter /v2/email-finder -q domain=stripe.com -q first_name=Patrick -q last_name=Collison
orth run tomba /v1/email-verifier -q email=<found>
```

## 3. Competitor social + brand + pricing

```bash
# social posts (search catalog for current LinkedIn/X providers)
orth run brand-dev /v1/brand/retrieve --body '{"domain":"notion.so"}'
orth run olostep /v1/scrapes --body '{"url_to_scrape":"https://notion.so/pricing","formats":["markdown"]}'
```

## 4. ICP prospecting

```bash
# natural-language people search (e.g. Fiber)
orth run fiber /v1/natural-language-search/profiles --body '{"query":"VP of Sales at Series B SaaS in SF","limit":10}'
# for each profile:
#   activity check → email find (tomba/hunter) → optional apollo enrich
```

## 5. Account-based marketing deep dive

```bash
orth run brand-dev /v1/brand/retrieve --body '{"domain":"figma.com"}'
# find execs via people search
# apollo match each linkedin_url / email
```

## 6. Trigger / news monitoring

```bash
orth run linkup /search --body '{"q":"stripe.com announcement funding launch","depth":"standard"}'
# optional: structured extract via a schema-extraction API in catalog (e.g. Riveter)
```

## 7. Web research answer

```bash
orth run tavily /search --body '{"query":"…","search_depth":"advanced","include_answer":true,"max_results":10}'
```

## Cost control checklist

1. Search once; pick one verified endpoint before looping
2. Quote when available for expensive enrichment
3. Cap list sizes (`limit`) on people/company search
4. Tell the user cumulative spend after multi-step chains
5. Stop immediately on 402
