# Resources And Concurrency

Use this reference when server-side logic needs bounded concurrency, retries, resource lifecycles, finalizers, pagination, streaming, or cleanup guarantees.

## Semaphore For Bounded Fan-Out

Use `Effect.makeSemaphore` when each item needs an Effect workflow but upstream fan-out must be capped.

```typescript
const syncOneAccount = Effect.fn('crm-sync.sync-one-account')(function* (target: SyncTarget) {
	const crm = yield* CrmSyncService
	return yield* crm.syncAccount({
		accountId: target.accountId,
		userId: target.userId,
	})
})

export const syncAccountsWithLimit = Effect.fn('crm-sync.sync-accounts-with-limit')(function* (params: {
	targets: SyncTarget[]
	concurrency: number
}) {
	const semaphore = yield* Effect.makeSemaphore(params.concurrency)

	const results = yield* Effect.all(
		params.targets.map((target) => semaphore.withPermits(1)(syncOneAccount(target))),
		{ concurrency: 'unbounded' }
	)

	yield* Effect.annotateCurrentSpan({
		'crm.sync.target_count': params.targets.length,
		'crm.sync.concurrency': params.concurrency,
	})

	return results
})
```

Use `Effect.all(..., { concurrency: n })` for simple cases. Use a semaphore when permits need to be shared across nested operations or multiple groups.

## Retry Without Dot-Pipe Chains

Use data-first `Effect.retry`. Let callers provide an optional `Schedule` when retry behavior should differ between tests, background jobs, and live route handlers.

```typescript
import { HttpClient, HttpClientRequest } from '@effect/platform'
import { Effect } from 'effect'

const fetchVendorPage = Effect.fn('vendor.fetch-page')(function* (url: string) {
	const http = yield* HttpClient.HttpClient
	const response = yield* http.execute(HttpClientRequest.get(url))

	if (response.status === 429) {
		return yield* Effect.fail(
			new VendorRateLimitError({
				operation: 'fetchPage',
				retryAfter: response.headers['retry-after'],
			})
		)
	}

	return yield* response.text
})
```

```typescript
import { Effect, Option, Schedule } from 'effect'

export const extractVendorObjects = Effect.fn('vendor.extract-objects')(function* (params: {
	url: string
	retrySchedule?: Schedule.Schedule<unknown, VendorRateLimitError | VendorFetchError>
}) {
	const request = fetchVendorPage(params.url)
	const schedule = Option.fromNullable(params.retrySchedule)

	if (Option.isSome(schedule)) {
		return yield* Effect.retry(request, schedule.value)
	}

	return yield* Effect.retry(request, Schedule.exponential('1 second'))
})
```

Respect vendor rate limits before retrying. If a response includes `Retry-After`, map it to a tagged rate-limit error with the retry-after value and let the caller decide whether to sleep, reschedule, or fallback.

## Streaming Pagination

Use async generators, `Stream`, or bounded loops for crawls and paginated APIs. Keep the visited set in an Effect collection and yield each page as it is discovered instead of loading every URL into memory first.

```typescript
import { Effect, HashSet } from 'effect'

export async function* discoverPages(seedUrl: string, maxPages = 20): AsyncGenerator<string> {
	let pending = [seedUrl]
	let visited = HashSet.empty<string>()

	while (pending.length > 0 && HashSet.size(visited) < maxPages) {
		const nextUrl = pending.shift()
		if (!nextUrl || HashSet.has(visited, nextUrl)) {
			continue
		}

		visited = HashSet.add(visited, nextUrl)
		yield nextUrl

		const discovered = await discoverNextPageLinks(nextUrl)
		pending = [...pending, ...discovered]
	}
}

export const extractAllPages = Effect.fn('vendor.extract-all-pages')(function* (seedUrl: string) {
	const results: VendorObject[] = []

	for await (const pageUrl of discoverPages(seedUrl)) {
		const page = yield* fetchVendorPage(pageUrl)
		results.push(...page.objects)
	}

	return results
})
```

Use the right in-memory primitive for the operation. `HashSet`/`HashMap` are useful for dedupe and indexing, but `Chunk`, `Option`, `Either`, `Predicate`, `Record`, `Array`, `Stream`, or plain TypeScript collections may be clearer depending on the data shape and lifecycle.

## Scoped Resource

Use `Effect.acquireRelease` for resources that can be acquired once and then used inside a larger scoped program.

```typescript
const acquireBrowserPool = Effect.fn('browser-pool.acquire')(function* (options: PoolOptions) {
	const poolService = yield* BrowserPoolService
	return yield* poolService.initPool(options)
})

const releaseBrowserPool = Effect.fn('browser-pool.release')(function* (pool: PoolState) {
	const poolService = yield* BrowserPoolService
	yield* Effect.ignore(poolService.closePool(pool))
})

export const browserPoolResource = Effect.fn('browser-pool.resource')(function* (options: PoolOptions) {
	return yield* Effect.acquireRelease(acquireBrowserPool(options), (pool) => releaseBrowserPool(pool))
})

export const scrapeWithPool = Effect.fn('browser-pool.scrape-with-pool')(function* (url: string) {
	const pool = yield* browserPoolResource({ maxTabs: 4 })
	const poolService = yield* BrowserPoolService

	return yield* poolService.withTab(pool, (session, page) =>
		scrapePageWithTab({
			session,
			page,
			url,
		})
	)
})

await Effect.runPromise(Effect.scoped(Effect.provide(scrapeWithPool(url), BrowserPoolLive)))
```

## Acquire Use Release

Use `Effect.acquireUseRelease` when acquisition, use, and release are a single operation.

```typescript
const createTempFile = Effect.fn('files.create-temp-file')(function* (contents: string) {
	return yield* Effect.tryPromise({
		try: () => writeTempFile(contents),
		catch: (cause) =>
			new FileResourceError({
				operation: 'createTempFile',
				message: 'failed to create temp file',
				cause,
			}),
	})
})

const uploadTempFile = Effect.fn('files.upload-temp-file')(function* (file: TempFile) {
	const storage = yield* R2StorageService
	return yield* storage.upload(file.path)
})

const removeTempFile = Effect.fn('files.remove-temp-file')(function* (file: TempFile) {
	yield* Effect.promise(() => rm(file.path, { force: true }))
})

export const uploadGeneratedFile = Effect.fn('files.upload-generated-file')(function* (contents: string) {
	return yield* Effect.acquireUseRelease(createTempFile(contents), uploadTempFile, removeTempFile)
})
```

Finalizers must be best-effort and must not fail. Map cleanup errors to `Effect.void` or handle them inside the finalizer.
