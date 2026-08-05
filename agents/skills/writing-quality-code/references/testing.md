# Testing Effect Code

Use this reference when adding or updating tests for server-side Effect code.

## Mock Layers

Provide test doubles with `Layer.succeed`.

```typescript
const CrmSyncMockLive = Layer.succeed(
	CrmSyncService,
	CrmSyncService.of({
		syncAccount: Effect.fn('test.crm-sync.syncAccount')(function* (params) {
			return {
				accountId: params.accountId,
				status: 'synced' as const,
			}
		}),
	})
)

test('syncs an account', async () => {
	const result = await Effect.runPromise(
		Effect.provide(runCrmSync({ accountId: 'acct-1', userId: 'user-1' }), CrmSyncMockLive)
	)

	expect(result).toEqual({
		accountId: 'acct-1',
		status: 'synced',
	})
})
```

Test doubles should still use `Effect.fn` for effectful service methods so failures remain traceable in larger test runs.

## Mock HTTP Client Layers

For provider/client tests, replace `HttpClient.HttpClient` with a deterministic layer instead of mocking `globalThis.fetch`. Route tests should usually mock the higher-level Promise facade that the route imports.

```typescript
import { HttpClient, HttpClientResponse } from '@effect/platform'
import { Effect, Layer } from 'effect'

const HttpClientMockLive = Layer.succeed(
	HttpClient.HttpClient,
	HttpClient.make((request) =>
		Effect.succeed(
			HttpClientResponse.fromWeb(
				request,
				new Response(JSON.stringify({ id: 'acct_1', name: 'Acme' }), {
					status: 200,
					headers: { 'content-type': 'application/json' },
				})
			)
		)
	)
)

test('decodes the vendor account response', async () => {
	const result = await Effect.runPromise(Effect.provide(fetchVendorAccount('acct_1'), HttpClientMockLive))

	expect(result).toEqual({ id: 'acct_1', name: 'Acme' })
})
```

If the behavior under test is route-level validation, auth, response mapping, or status codes, mock the route's domain module instead. Use the HTTP client mock only when testing the provider/client module that owns HTTP behavior.

## Failure Assertions

Prefer `Effect.runPromiseExit` for failure assertions. It preserves the typed failure in the error channel without pushing `Effect.either` into production-style orchestration.

```typescript
import { Cause, Effect, Exit } from 'effect'

test('returns a tagged error for missing account', async () => {
	const exit = await Effect.runPromiseExit(
		Effect.provide(runCrmSync({ accountId: 'missing', userId: 'user-1' }), CrmSyncMockLive)
	)

	expect(Exit.isFailure(exit)).toBe(true)
	const failure = Exit.isFailure(exit) ? Cause.failureOption(exit.cause) : undefined
	expect(failure?._tag).toBe('Some')
	expect(failure?._tag === 'Some' ? failure.value._tag : undefined).toBe('CrmRecordNotFoundError')
})
```

Use `Effect.either` only in tests that are explicitly exercising an API returning `Either`. Normal service tests should assert the original success or failure shape.

## Test Through The Public Service

When a live implementation composes multiple provider layers, test the public service behavior and use deterministic provider doubles for each branch. Keep provider ordering observable through results, spans, or fake call counts instead of depending on private implementation details.

```typescript
const PrimaryFailureLive = Layer.succeed(
	ObjectExtractionProvider,
	ObjectExtractionProvider.of({
		extractPage: Effect.fn('test.object-extraction.primary-failure')(function* () {
			return yield* Effect.fail(
				new ProviderFetchError({
					operation: 'extractPage',
					message: 'primary provider failed',
				})
			)
		}),
	})
)

const FallbackSuccessLive = Layer.succeed(
	ObjectExtractionProvider,
	ObjectExtractionProvider.of({
		extractPage: Effect.fn('test.object-extraction.fallback-success')(function* () {
			return { objects: [{ name: 'Acme' }] }
		}),
	})
)
```

Test doubles should still invoke zero-argument `Effect.fn` helpers before yielding them. An uninvoked function is not an Effect and will not execute.

## Scoped Resource Tests

Wrap resource programs in `Effect.scoped` so finalizers run during the test.

```typescript
test('closes the browser pool after use', async () => {
	const result = await Effect.runPromise(
		Effect.scoped(Effect.provide(scrapeWithPool('https://example.com'), BrowserPoolMockLive))
	)

	expect(result.title).toBe('Example Domain')
	expect(poolClosed).toBe(true)
})
```

## Concurrency Tests

For semaphore-backed functions, assert behavior through observable limits rather than sleeping longer than necessary.

```typescript
test('limits concurrent sync work', async () => {
	let active = 0
	let maxActive = 0

	const service = CrmSyncService.of({
		syncAccount: Effect.fn('test.crm-sync.limited-sync')(function* (params) {
			active += 1
			maxActive = Math.max(maxActive, active)
			yield* Effect.sleep('10 millis')
			active -= 1
			return { accountId: params.accountId, status: 'synced' as const }
		}),
	})

	await Effect.runPromise(
		Effect.provide(
			syncAccountsWithLimit({
				targets: targetsFixture,
				concurrency: 2,
			}),
			Layer.succeed(CrmSyncService, service)
		)
	)

	expect(maxActive).toBeLessThanOrEqual(2)
})
```

Keep pure helper tests plain Bun tests unless the helper needs Effect dependencies or error-channel assertions.
