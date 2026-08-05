# Error Handling

Use this reference when modeling, mapping, recovering from, or exposing failures in Effect code.

## Model Expected Failures

Use `Data.TaggedError` for expected domain, integration, validation, and infrastructure failures that callers should handle.

```typescript
import { Data } from 'effect'

export class CrmSyncError extends Data.TaggedError('CrmSyncError')<{
	readonly operation: 'loadAccount' | 'syncAccount' | 'rateLimited'
	readonly message: string
	readonly retryAfter?: string
	readonly cause?: unknown
}> {}

export class CrmRecordNotFoundError extends Data.TaggedError('CrmRecordNotFoundError')<{
	readonly provider: 'affinity' | 'attio' | 'dealcloud'
	readonly externalId: string
}> {}

export type CrmSyncServiceError = CrmSyncError | CrmRecordNotFoundError
```

Rules:

- Include operation names and safe identifiers.
- Include fields that change behavior: `provider`, `code`, `operation`, `retryAfter`, `recoverable`, `field`.
- Do not include plaintext secrets, tokens, emails, raw note bodies, OAuth payloads, CRM records, or large third-party payloads.
- Keep `cause` for diagnostics only; do not rely on parsing `cause` for business decisions.

## Match Error Values Exhaustively

Do not define rich error values and then ignore them. At boundaries, match on `_tag` first, then branch on meaningful fields.

For tagged unions, prefer Effect's `Match.tagsExhaustive` or `Match.exhaustive` so TypeScript catches new error variants that are not handled. `Effect.match` / `Effect.matchEffect` handles success versus failure; `Match` handles the failure value exhaustively.

```typescript
import { Effect, Match, pipe } from 'effect'

type RouteResult =
	| { readonly status: 200; readonly body: { readonly ok: true; readonly result: CrmSyncResult } }
	| { readonly status: 404; readonly body: { readonly ok: false; readonly message: string } }
	| { readonly status: 429; readonly body: { readonly ok: false; readonly retryAfter?: string } }
	| { readonly status: 500 | 502; readonly body: { readonly ok: false; readonly message: string } }

const mapCrmSyncErrorToRouteResult = pipe(
	Match.type<CrmSyncServiceError>(),
	Match.tagsExhaustive({
		CrmRecordNotFoundError: (error): RouteResult => ({
			status: 404,
			body: {
				ok: false,
				message: `${error.provider} record was not found`,
			},
		}),
		CrmSyncError: (error): RouteResult => {
			if (error.operation === 'rateLimited') {
				return { status: 429, body: { ok: false, retryAfter: error.retryAfter } }
			}

			if (error.operation === 'loadAccount') {
				return { status: 502, body: { ok: false, message: 'Unable to load CRM account' } }
			}

			return { status: 500, body: { ok: false, message: 'CRM sync failed' } }
		},
	})
)

const syncRouteResult = Effect.match(runCrmSyncEffect(params), {
	onSuccess: (result): RouteResult => ({ status: 200, body: { ok: true, result } }),
	onFailure: mapCrmSyncErrorToRouteResult,
})
```

Prefer this over a single catch-all message. Error fields are part of the domain model; use them deliberately and keep them telemetry-safe.

## Recover Without Swallowing

For recoverable branches inside Effect programs, use `Effect.catchTags` and preserve unhandled failures.

```typescript
const syncWithFallback = Effect.catchTags(syncFromPrimaryProvider(params), {
	CrmRecordNotFoundError: (error) => {
		if (error.provider === 'affinity') {
			return syncFromBackupProvider(params)
		}

		return Effect.fail(error)
	},
	CrmSyncError: (error) => {
		if (error.operation === 'rateLimited') {
			return rescheduleSync(params, error.retryAfter)
		}

		return Effect.fail(error)
	},
})
```

Use `Effect.catchTags` for recovery and fallback. Use `Effect.match` for pure boundary mapping and `Effect.matchEffect` when the success or failure handlers need to return Effects.

## Promise And Unsafe Boundaries

Keep `Effect.tryPromise` at the smallest unsafe boundary: one DB query/mutation, one vendor SDK call, one filesystem read, or one legacy Promise adapter.

```typescript
const loadCrmAccount = Effect.fn('crm-sync.load-account')(function* (params: { accountId: string }) {
	const db = yield* DatabaseService
	return yield* Effect.tryPromise({
		try: () =>
			db.query.account.findFirst({
				where: eq(account.externalId, params.accountId),
			}),
		catch: (cause) =>
			new CrmSyncError({
				operation: 'loadAccount',
				message: 'CRM sync operation failed: loadAccount',
				cause,
			}),
	})
})
```

Avoid broad `try/catch` inside Effect code and avoid `Effect.either` in production orchestration unless the domain API explicitly returns an `Either`.
