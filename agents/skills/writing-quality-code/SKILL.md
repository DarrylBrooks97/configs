---
name: writing-quality-code
description: 'Personal code-quality guidance for business logic, utility functions, TypeScript correctness, server/client boundaries, and server-side Effect-TS. Use when writing or reviewing domain logic, reusable helpers, backend services, API internals, workflow programs, type-safe data flow, client/server placement, typed errors, tracing, concurrency, redaction, or tests.'
---

# Writing Quality Code

Use this skill for business logic, reusable utility functions, TypeScript data flow, server/client boundaries, and server-side code that needs composition, clear domain decisions, IO, dependencies, typed failures, retries, tracing, resource lifecycles, concurrency, database writes, external APIs, or workflow orchestration.

## Quality Defaults

- Keep code simple, dry, explicit, and easy to read before reaching for abstractions.
- Prefer small named functions that describe domain decisions over inline conditionals buried in handlers, callbacks, or Promise closures.
- Add comments around non-obvious business logic, invariants, tradeoffs, or policy decisions so future readers understand why the code behaves that way; do not comment obvious mechanics.
- Separate pure decisions from IO: parse/validate inputs, compute the decision, then persist or call external systems.
- Make utility functions deterministic, typed at the boundary, and narrow in purpose. Avoid hidden global state, mutation-heavy helpers, and catch-all `utils` modules.
- Compose around domain concepts, not transport details. If logic is reused across apps, move it into `packages/*`; never import directly across `apps/*`.
- Hide Effect-TS at normal TypeScript call sites. Non-Effect callers should call `async`/`Promise` functions with `await`, not build/provide/run Effect programs themselves.
- Add focused tests for business rules, type/runtime boundary behavior, edge cases, and failure mapping before broad integration checks.

## TypeScript And Runtime Checks

- Prefer precise domain types over loose objects, stringly-typed flags, or `any`/unsafe casts.
- Validate untrusted inputs at boundaries: use `effect/Schema` in server-side Effect code and Zod v4 where existing Elysia/product route contracts use Zod. Cover external webhooks, API bodies, env/config, AI output, queue payloads, and database-adjacent decoded JSON.
- Normalize once at ingress, then pass normalized types through domain logic.
- Keep type narrowing close to the branch that proves it; avoid exporting partially validated values.
- Use schemas, discriminated unions, type guards, and precise TypeScript types to make narrowing obvious instead of compensating with clever conditionals.
- Use ternaries only for a single simple condition and expression. If the check needs nesting, repeated ternaries, type narrowing, multiple predicates, or explanation, use `if` statements or a named helper instead.
- Use discriminated unions or tagged errors for business outcomes that callers must handle.
- Treat type errors as design feedback. Do not silence them with broad casts, `ts-ignore`, or lossy wrapper types unless the unsafe edge is isolated and documented.

## Server, Client, And Package Boundaries

- Keep server-only logic, secrets, DB access, vendor SDKs, and Effect programs out of client components and browser bundles.
- Keep client components focused on presentation, user interaction, and typed hooks; move business decisions and mutations behind server APIs or shared pure helpers.
- Product API calls should use the project's typed client and focused query hooks instead of ad hoc raw requests.
- Shared code belongs in `packages/*`; do not import directly across `apps/*`.
- Add new environment variables to `turbo.json` and validate them at runtime boundaries.
- Protect PII: encrypt where required and never log raw customer data, tokens, emails, notes, OAuth payloads, CRM records, or third-party payloads.

## Reusable Utility Shape

1. Name the domain operation, not the implementation trick.
2. Accept explicit inputs and return explicit outputs; avoid reading process/env/request state inside helpers.
3. Keep validation close to untrusted boundaries and keep normalized types inside the domain layer.
4. Prefer total functions where practical; otherwise return a typed result/error instead of throwing ad hoc errors.
5. Place shared utilities near the domain package that owns them, not in a generic dumping ground.

## When To Use Effect

- Use Effect for server-side business logic, services, workflow programs, reusable HTTP/vendor clients, queues, database writes, AI calls, retries, tracing, scoped resources, and bounded concurrency.
- Use plain TypeScript for UI-only code, DTO declarations, tiny pure helpers, and one-off synchronous transforms with no IO, dependency, error channel, or tracing need.
- Do not wrap code in Effect just to look consistent; use Effect when it makes dependencies, failure modes, retries, tracing, resources, or concurrency clearer.

## Caller Boundary Rule

- If the caller is normal TypeScript, expose a normal TypeScript facade: `async function doThing(input): Promise<Result>` and let it `await` like any other function.
- Keep `Effect.runPromise`, `Effect.provide`, live layer composition, and final tagged-error-to-response mapping inside a thin adapter at the module, route, workflow, script, or job boundary.
- If the caller is already inside an Effect program, call the Effect function directly with `yield* doThingEffect(input)`; do not bounce through the Promise facade.
- Avoid leaking `Effect.Effect<...>` return types, `Layer` wiring, `Context` tags, or `Effect.runPromise` requirements into ordinary route handlers, React Query hooks, queue handlers, scripts, or utility consumers.
- Naming convention: use a private or clearly internal `runThingEffect`/`thingProgram` for the Effect program and export `thing`/`doThing` as the Promise-returning facade for non-Effect callers.

## Effect Core Rules

- Use `Effect.fn('domain.operation')(function* (...) { ... })` for effectful or non-deterministic server-side functions.
- Use `Effect.fnUntraced(function* (...) { ... })` for deterministic Effect helpers that need generator ergonomics or typed failures.
- Use `Effect.gen` only inside an `Effect.fn`, layer/resource constructor, or tiny inline anonymous Effect.
- Call every `Effect.fn`/`Effect.fnUntraced` before yielding, providing, retrying, or running it. Zero-argument helpers still need `program()`.
- Sequence normal control flow with `yield*`; avoid `.pipe()` chains in server-side Effect code.
- Prefer data-first APIs: `Effect.provide(effect, layer)`, `Effect.catchTags(effect, handlers)`, `Effect.matchEffect(effect, handlers)`, `Effect.retry(effect, schedule)`, `Effect.withSpan(effect, name, options)`.
- Every Effect value must be yielded, returned, provided, or run.
- Model expected failures with `Data.TaggedError`; avoid `try/catch` inside Effect code and avoid `Effect.either` in production orchestration.
- Match on tagged error values at boundaries with `Effect.catchTags`/`Effect.matchEffect`: branch on `_tag` first, then meaningful fields such as `operation`, `provider`, `code`, `retryAfter`, or `recoverable`.
- Keep `Effect.tryPromise` at the smallest unsafe boundary: one DB query/mutation, one vendor SDK call, one filesystem read, or one legacy Promise adapter.

## Performance Optimization

Optimize only after the business logic is validated and core tests already cover expected behavior, edge cases, and failure paths. Correctness and maintainability come first.

- Start with simple, readable code and measure before changing it.
- Use profiling, traces, database query plans, or concrete user-facing symptoms to justify optimization work.
- Keep optimizations local and documented: explain the bottleneck, the tradeoff, and why the added complexity is acceptable.
- Preserve existing tests and add focused regression/performance-adjacent coverage when an optimization changes data flow, caching, batching, concurrency, pagination, or query shape.
- Prefer structural wins before micro-optimizations: fewer round trips, bounded concurrency, streaming/pagination, better indexes, better query shapes, memoization with clear invalidation, and avoiding repeated parsing or allocation in hot paths.
- Do not obscure domain rules for speed unless the fast path is isolated behind a named helper with tests.

## Server-Side Mutation Shape

1. Expose a normal `async` facade for route/job/script callers unless the caller is already in Effect.
2. In the internal Effect program, load data with a small typed IO function.
3. Validate and decide with `Effect.fnUntraced` or a pure helper.
4. Persist through small typed IO functions.
5. Record audit/analytics through their service boundaries.
6. Map tagged failures at the facade, route, or workflow boundary by matching the error value, not by collapsing every failure into one generic message.

## Domain Service Module Shape

Prefer domain-first names for focused service modules. Do not name directories after the implementation style, such as `*-effect`; Effect should be an implementation detail, not the domain name.

```text
feature-name/
  errors.ts
  types.ts
  service.ts
  layers.ts
  validation.ts
  index.ts
  __tests__/
```

Small features may combine files when splitting would add noise.

## Safety, Tracing, And Scale

- Define services only when dependency injection, test doubles, replacement implementations, or shared boundaries justify them.
- Build one public `Context.GenericTag` per domain capability and hide provider-specific `*Live` layers behind it.
- Never use native `fetch` in new server-side business logic, integration clients, workflow code, or reusable utilities; use Effect Platform `HttpClient` from `@effect/platform` and provide `FetchHttpClient.layer` at the runtime boundary.
- Accept an optional caller-provided `Schedule` when live implementations need retry tuning. Respect vendor `Retry-After` before generic retries.
- Wrap secrets, tokens, email addresses, raw payloads, notes, and other log-sensitive values with `Redacted` at ingress. Unwrap only at API, encryption, or persistence boundaries.
- Use the right Effect/data primitive for in-memory transformations in Effect service code: `HashSet`/`HashMap`, `Chunk`, `Option`, `Either`, `Predicate`, `Record`, `Array`, `Stream`, or plain TypeScript collections depending on the operation.
- Use async generators, `Stream`, or bounded iteration for pagination/crawls. Do not preload every URL or page into memory.
- Use scoped resources and semaphores for lifecycles and bounded concurrency.
- Audit user-visible user/system actions with `recordAuditEvent` / `AuditLogService`; keep required audit writes in the same DB transaction as the mutation and attach recovery data only when the action is recoverable.
- Run `bun install` when dependencies/package metadata change so `bun.lock` is fresh, then `bun fmt && bun check`.

## Reference Loading

Load only the specific reference file needed for concrete examples:

- [Effect service and layer patterns](references/services-and-layers.md): service tags, layer constructors, `Effect.Service`, and dependency wiring.
- [Error handling](references/error-handling.md): tagged errors, exhaustive error-value matching, recovery, and unsafe boundary mapping.
- [Effect Platform HTTP Client](references/http-client.md): server-side HTTP calls without native `fetch`, request/response schemas, and `FetchHttpClient.layer` wiring.
- [Schema encoding and decoding](references/schema.md): `effect/Schema` for decoding ingress payloads, encoding egress bodies, and typed transport/domain shapes.
- [Effect caller boundaries](references/workflow-boundaries.md): Promise facades for normal TypeScript callers, direct `yield*` for Effect callers, Inngest/API/script adapters.
- [Effect resources and concurrency](references/resources-and-concurrency.md): semaphores, scoped resources, `acquireRelease`, `acquireUseRelease`, retries.
- [Sensitive data and redaction](references/redaction.md): `Redacted`, config secrets, telemetry-safe attributes, encryption boundaries.
- [Testing](references/testing.md): mock layers, failure assertions, scoped tests, concurrency tests.
