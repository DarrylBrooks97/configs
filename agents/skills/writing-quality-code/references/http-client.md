# Effect Platform HTTP Client

Use this reference when server-side code calls external or internal HTTP APIs.

## Rule

Do not use native `fetch` in new server-side business logic, integration clients, workflow code, or reusable utilities. Use `@effect/platform` `HttpClient` with `FetchHttpClient.layer` at the runtime boundary.

Exceptions need a deliberate reason, such as browser/client code, service workers, framework APIs that require `fetch`, healthcheck one-liners, or legacy code being touched outside the scope of a change.

## Basic Request

```typescript
import { FetchHttpClient, HttpClient, HttpClientRequest, HttpClientResponse } from '@effect/platform'
import { Data, Effect, Layer } from 'effect'
import * as Schema from 'effect/Schema'

class VendorHttpError extends Data.TaggedError('VendorHttpError')<{
	readonly operation: 'fetchAccount'
	readonly status?: number
	readonly retryAfter?: string
	readonly message: string
	readonly cause?: unknown
}> {}

const VendorAccountResponse = Schema.Struct({
	id: Schema.String,
	name: Schema.String,
	updatedAt: Schema.String,
})

type VendorAccountResponse = Schema.Schema.Type<typeof VendorAccountResponse>

const fetchVendorAccount = Effect.fn('vendor.fetch-account')(function* (accountId: string) {
	const http = yield* HttpClient.HttpClient

	const request = HttpClientRequest.setHeader(
		HttpClientRequest.get(`https://api.vendor.com/accounts/${accountId}`),
		'accept',
		'application/json'
	)

	const response = yield* http.execute(request)

	if (response.status === 429) {
		return yield* Effect.fail(
			new VendorHttpError({
				operation: 'fetchAccount',
				status: response.status,
				retryAfter: response.headers['retry-after'],
				message: 'vendor rate limited account fetch',
			})
		)
	}

	if (response.status < 200 || response.status >= 300) {
		return yield* Effect.fail(
			new VendorHttpError({
				operation: 'fetchAccount',
				status: response.status,
				message: 'vendor account fetch failed',
			})
		)
	}

	return yield* Effect.mapError(
		HttpClientResponse.schemaBodyJson(VendorAccountResponse)(response),
		(cause) =>
			new VendorHttpError({
				operation: 'fetchAccount',
				status: response.status,
				message: 'vendor account response was invalid',
				cause,
			})
	)
})

export const VendorAccountBaseLive = Layer.effect(
	VendorAccountService,
	Effect.gen(function* () {
		return VendorAccountService.of({ fetchAccount: fetchVendorAccount })
	})
)

export const VendorAccountLive = Layer.provide(VendorAccountBaseLive, FetchHttpClient.layer)
```

## JSON Request Bodies

Use `HttpClientRequest.schemaBodyJson` when request payloads should be encoded through Schema.

```typescript
const CreateAccountRequest = Schema.Struct({
	name: Schema.String,
	domain: Schema.String,
})

const buildCreateAccountRequest = HttpClientRequest.schemaBodyJson(CreateAccountRequest)

const createVendorAccount = Effect.fn('vendor.create-account')(function* (input: Schema.Schema.Type<typeof CreateAccountRequest>) {
	const http = yield* HttpClient.HttpClient
	const request = yield* buildCreateAccountRequest(
		HttpClientRequest.post('https://api.vendor.com/accounts'),
		input
	)

	return yield* http.execute(HttpClientRequest.setHeader(request, 'accept', 'application/json'))
})
```

## Layering

Provider clients should depend on `HttpClient.HttpClient`, not on global fetch. Provide the concrete implementation once at the edge:

```typescript
export const VendorLive = Layer.provide(VendorBaseLive, FetchHttpClient.layer)
```

Tests can provide a mock `HttpClient.HttpClient` layer or use higher-level service mocks. Do not thread `fetch`, raw clients, tokens, or database handles through request objects when they belong in Effect context.
