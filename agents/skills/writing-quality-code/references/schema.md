# Schema Encoding And Decoding

Use this reference when validating untrusted data, decoding external shapes into domain types, encoding domain values for requests/storage, or parsing HTTP payloads.

## Rule

Use `effect/Schema` for server-side Effect code. Use Zod v4 where existing Elysia/product route contracts already use Zod or where non-Effect client code needs Zod. Do not pass unvalidated `unknown` from HTTP, webhooks, AI, queue payloads, env/config, or decoded JSON into domain logic.

## Decode At Ingress

Decode untrusted input once at the boundary, then pass the decoded type through domain logic.

```typescript
import { Data, Effect } from 'effect'
import * as Schema from 'effect/Schema'

class DecodePayloadError extends Data.TaggedError('DecodePayloadError')<{
	readonly operation: 'decodeVendorAccount'
	readonly message: string
	readonly cause?: unknown
}> {}

class EncodePayloadError extends Data.TaggedError('EncodePayloadError')<{
	readonly operation: 'encodeCreateVendorAccountBody'
	readonly message: string
	readonly cause?: unknown
}> {}

const VendorAccountPayload = Schema.Struct({
	id: Schema.String,
	name: Schema.NonEmptyString,
	owner_count: Schema.NumberFromString,
	updated_at: Schema.DateFromString,
})

type VendorAccountPayload = Schema.Schema.Type<typeof VendorAccountPayload>
type VendorAccountPayloadEncoded = Schema.Schema.Encoded<typeof VendorAccountPayload>

const decodeVendorAccountPayload = Effect.fn('vendor.decode-account-payload')(function* (input: unknown) {
	return yield* Effect.mapError(
		Schema.decodeUnknown(VendorAccountPayload)(input),
		(cause) =>
			new DecodePayloadError({
				operation: 'decodeVendorAccount',
				message: 'vendor account payload was invalid',
				cause,
			})
	)
})
```

`Schema.Schema.Type<typeof SchemaName>` is the decoded domain-facing type. `Schema.Schema.Encoded<typeof SchemaName>` is the transport/storage-facing shape.

## Encode At Egress

Encode domain values before sending them to external APIs or storing encoded JSON.

```typescript
const CreateVendorAccountBody = Schema.Struct({
	name: Schema.NonEmptyString,
	domain: Schema.String,
	seat_count: Schema.NumberFromString,
})

type CreateVendorAccountBody = Schema.Schema.Type<typeof CreateVendorAccountBody>

type CreateVendorAccountBodyEncoded = Schema.Schema.Encoded<typeof CreateVendorAccountBody>

const encodeCreateVendorAccountBody = Effect.fn('vendor.encode-create-account-body')(function* (
	body: CreateVendorAccountBody
) {
	return yield* Effect.mapError(
		Schema.encode(CreateVendorAccountBody)(body),
		(cause) =>
			new EncodePayloadError({
				operation: 'encodeCreateVendorAccountBody',
				message: 'vendor account request body could not be encoded',
				cause,
			})
	)
})
```

## HTTP Response Decoding

With `@effect/platform`, decode JSON responses through `HttpClientResponse.schemaBodyJson` instead of calling `response.json()` manually.

```typescript
import { HttpClientResponse } from '@effect/platform'

const account = yield* Effect.mapError(
	HttpClientResponse.schemaBodyJson(VendorAccountPayload)(response),
	(cause) =>
		new DecodePayloadError({
			operation: 'decodeVendorAccount',
			message: 'vendor account response body was invalid',
			cause,
		})
)
```

For requests, use `HttpClientRequest.schemaBodyJson` so the body is encoded through the schema before being sent.

## Synchronous Helpers

Use synchronous decoding only for deterministic local data where throwing is acceptable at module setup or test setup. Runtime boundaries should use Effect-returning decoders so parse failures stay typed.

```typescript
const decodeFixture = Schema.decodeUnknownSync(VendorAccountPayload)
const fixture = decodeFixture({ id: 'acct_1', name: 'Acme', owner_count: '3', updated_at: '2026-07-02' })
```

## Practices

- Keep schemas next to the boundary or domain module that owns the contract.
- Decode external naming into internal naming at the boundary when practical.
- Use transformations like `Schema.NumberFromString` and `Schema.DateFromString` to normalize transport values.
- Map `ParseError` into tagged domain errors with safe metadata.
- Do not log raw payloads on parse failure; include counts, operation names, safe IDs, and redacted excerpts only when necessary.
