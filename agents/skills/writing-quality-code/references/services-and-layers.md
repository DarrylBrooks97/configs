# Service And Layer Patterns

Use this reference when creating or reviewing server-side Effect services.

## Service Tag

Use a service abstraction when the dependency needs test doubles, multiple implementations, or a clear app/package boundary.

```typescript
import { Context, Effect } from 'effect'

import type { CrmSyncError } from './errors'
import type { CrmSyncResult } from './types'

export interface CrmSyncService {
	syncAccount: (params: { accountId: string; userId: string }) => Effect.Effect<CrmSyncResult, CrmSyncError>
}

export const CrmSyncService = Context.GenericTag<CrmSyncService>('@app/workflows/CrmSyncService')
```

Use namespaced tags for shared or app-level services: `@app/workflows/Name`, `@app/core/Name`, `@app/browser-worker/Name`.

Service methods may return `Effect` internally, but ordinary TypeScript callers should receive Promise facades from the module boundary. Do not make non-Effect callers provide layers or run Effect programs.

## Layer Constructor Decision Table

Effect's docs define a layer as `Layer<RequirementsOut, Error, RequirementsIn>`: it builds one or more output services, can fail during construction, and may require input services.

Choose the narrowest constructor that matches construction:

| Constructor | Use when | Dependency shape |
| --- | --- | --- |
| `Layer.succeed(Tag, service)` | You already have a service value. No dependency lookup or construction effects are needed. | `Layer<Tag>` |
| `Layer.function(DependencyTag, ServiceTag, makeService)` | A service is synchronously derived from one dependency. | `Layer<ServiceTag, never, DependencyTag>` |
| `Layer.effect(ServiceTag, effect)` | Construction itself is an Effect: read config, validate, create an async client, map init failures, or yield multiple dependencies. | `Layer<ServiceTag, Error, Requirements>` |
| `Layer.scoped(ServiceTag, effect)` | Construction acquires a resource that must be released when the layer scope closes. | `Layer<ServiceTag, Error, Requirements>` |

Important distinction: a layer having a dependency does not automatically mean construction is effectful in the business sense. If it is just “given dependency A, build service B synchronously,” prefer `Layer.function`. Use `Layer.effect` when you need Effect operations during construction.

## Effect.Service With Dependencies

The Effect docs' `Effect.Service` pattern has merit for reducing boilerplate: it defines the tag and generated layers in one class, and its `dependencies` option can package the dependency graph with the default implementation.

```typescript
import { FileSystem } from '@effect/platform'
import { NodeFileSystem } from '@effect/platform-node'
import { Effect } from 'effect'

class Cache extends Effect.Service<Cache>()('@app/workflows/Cache', {
	effect: Effect.gen(function* () {
		const fs = yield* FileSystem.FileSystem

		return {
			lookup: (key: string) => fs.readFileString(`/tmp/cache/${key}`),
		}
	}),
	dependencies: [NodeFileSystem.layer],
}) {}
```

Use it deliberately:

- Good fit: small app-local services where the default implementation and dependency graph should travel together.
- Good fit: reducing repetitive tag/layer boilerplate when the team is comfortable with class-based services and generated layers.
- Be careful: the API is marked experimental in Effect 3.21, so avoid making it the default for stable shared package contracts until we commit to it.
- Be careful: `dependencies` can hide wiring. For tests that need to inject dependencies, prefer the generated dependency-free layer when available or keep an explicit `Base`/`Live` split.
- Default: explicit `Context.GenericTag` plus `Layer.succeed`/`Layer.function`/`Layer.effect` remains easier to read and review across packages.

If adopting `Effect.Service`, keep the caller-boundary rule: normal TypeScript callers still call Promise facades; only Effect programs yield the service or generated accessors directly.

## Pure Layer

Use `Layer.succeed` for a fully constructed service with no dependencies.

```typescript
import { Effect, Layer } from 'effect'

export const CrmSyncTestLive = Layer.succeed(
	CrmSyncService,
	CrmSyncService.of({
		syncAccount: Effect.fn('test.crm-sync.sync-account')(function* (params) {
			return { accountId: params.accountId, status: 'synced' as const }
		}),
	})
)
```

## Synchronous Dependency Layer

Use `Layer.function` when a live service only captures one dependency and returns service methods. This keeps the dependency visible in the layer type without pretending construction has init work.

```typescript
import { HttpClient, HttpClientRequest } from '@effect/platform'
import { Effect, Layer } from 'effect'

export const CloudflareObjectExtractionLive = Layer.function(
	HttpClient.HttpClient,
	ObjectExtractionProvider,
	(http) =>
		ObjectExtractionProvider.of({
			extractPage: Effect.fn('object-extraction.cloudflare.extract-page')(function* (request) {
				const response = yield* http.execute(HttpClientRequest.get(request.url))
				return yield* decodeCloudflareResponse(response)
			}),
		})
)
```

If construction synchronously needs more than one dependency, either compose smaller one-dependency layers or use `Layer.effect` with `Effect.gen` to yield the dependencies explicitly.

## Effectful Dependency Layer

Use `Layer.effect` when layer construction must run Effect code. Common cases:

- yielding multiple dependencies from context;
- reading `Config` or `Config.redacted`;
- validating configuration;
- constructing a client with `Effect.tryPromise`;
- mapping construction failures into typed errors.

```typescript
import { Config, Effect, Layer, Redacted } from 'effect'

export const VendorClientLive = Layer.effect(
	VendorClientService,
	Effect.gen(function* () {
		const db = yield* DatabaseService
		const apiKey = yield* Config.redacted('VENDOR_API_KEY')
		const client = yield* Effect.tryPromise({
			try: () => createVendorClient({ apiKey: Redacted.value(apiKey) }),
			catch: (cause) =>
				new VendorClientError({
					operation: 'createClient',
					message: 'failed to create vendor client',
					cause,
				}),
		})

		return VendorClientService.of({
			loadAccount: (accountId) => loadVendorAccount({ accountId, client, db }),
		})
	})
)
```

This layer requires `DatabaseService` and config at construction time. Provide dependencies at composition boundaries:

```typescript
export const VendorClientProductionLive = Layer.provide(VendorClientLive, PostgresLive)
```

Keep a `Base`/`Live` split when tests should inject dependencies:

```typescript
export const IntegrationServiceBase = Layer.function(DatabaseService, IntegrationService, createIntegrationService)
export const IntegrationLive = Layer.provide(IntegrationServiceBase, PostgresLive)
```

## Scoped Resource Layer

Use `Layer.scoped` for resources with lifecycles: pools, sockets, browser instances, temporary directories, long-lived clients that must close, or subscriptions.

```typescript
import { Effect, Layer } from 'effect'

export const BrowserPoolLive = Layer.scoped(
	BrowserPoolService,
	Effect.gen(function* () {
		const pool = yield* acquireBrowserPool({ maxTabs: 4 })

		yield* Effect.addFinalizer(() => releaseBrowserPool(pool))

		return BrowserPoolService.of({
			withPage: (url, usePage) => useBrowserPage(pool, url, usePage),
		})
	})
)
```

Do not use `Layer.effect` for resources that need cleanup; without scoped construction, release behavior is easy to lose.

## Public Service With Live Providers

Expose one domain service to callers, then hide provider ordering inside the live layer composition. Concrete implementations should be named for the provider and suffixed with `Live`; callers should depend on the public service tag, not on provider-specific services.

```typescript
import { FetchHttpClient } from '@effect/platform'
import { Effect, Layer } from 'effect'

const runProvider = Effect.fn('object-extraction.provider.run')(function* (request: ExtractRequest) {
	const provider = yield* ObjectExtractionProvider
	return yield* provider.extractPage(request)
})

const CloudflareWithHttpLive = Layer.provide(CloudflareObjectExtractionLive, FetchHttpClient.layer)

export const ObjectExtractionLive = Layer.succeed(
	ObjectExtractionService,
	ObjectExtractionService.of({
		extract: Effect.fn('object-extraction.extract')(function* (request) {
			return yield* Effect.catchTags(Effect.provide(runProvider(request), CloudflareWithHttpLive), {
				ProviderRateLimitError: (error) => Effect.fail(error),
				ProviderFetchError: () => Effect.provide(runProvider(request), ExaObjectExtractionLive),
			})
		}),
	})
)
```

If the fallback itself needs dependencies, compose those dependencies into the fallback layer once and keep the service method focused. Do not manually pass `http`, database handles, or vendor clients through request objects when they can be yielded from the Effect context.

## Related References

Keep this file focused on service and layer construction. Load the specific reference for cross-cutting behavior:

- [Error handling](error-handling.md): tagged errors, matching on error values, recovery, and Promise boundary mapping.
- [Effect Platform HTTP Client](http-client.md): server-side HTTP calls without native `fetch`.
- [Schema encoding and decoding](schema.md): decoding ingress payloads and encoding egress bodies.
- [Sensitive data and redaction](redaction.md): redacted values, safe telemetry, and encryption boundaries.

`Effect.fn` returns a function. Invoke zero-argument functions too:

```typescript
const loadConfig = Effect.fn('vendor.load-config')(function* () {
	return yield* Config.redacted('VENDOR_API_KEY')
})

const config = yield* loadConfig()
```

Do not log or annotate plaintext from `Redacted.value`. See `redaction.md` before touching sensitive values.
