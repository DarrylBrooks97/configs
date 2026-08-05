# Sensitive Data And Redaction

Use this reference before handling secrets, OAuth tokens, emails, note bodies, CRM payloads, generated outreach, raw webhook payloads, or other sensitive server-side values.

## Redacted At Ingress

Wrap sensitive values as soon as they enter Effect code.

```typescript
import { Config, Effect, Redacted } from 'effect'

export interface VendorRequest {
	readonly userId: string
	readonly email: Redacted.Redacted
	readonly accessToken: Redacted.Redacted
}

export const buildVendorRequest = Effect.fn('vendor.build-request')(function* (params: {
	userId: string
	email: string
}) {
	const accessToken = yield* Config.redacted('VENDOR_ACCESS_TOKEN')

	return {
		userId: params.userId,
		email: Redacted.make(params.email),
		accessToken,
	} satisfies VendorRequest
})
```

Prefer `Config.redacted` for env secrets. Use `Redacted.make` for request fields or decrypted values that must temporarily exist in memory.

## Unwrap Only At The Boundary

Use `Redacted.value` only at the exact boundary that requires plaintext: an outbound vendor request, encryption call, or database persistence path that already encrypts PII.

```typescript
export const sendVendorRequest = Effect.fn('vendor.send-request')(function* (request: VendorRequest) {
	const response = yield* Effect.tryPromise({
		try: () =>
			vendorClient.send({
				email: Redacted.value(request.email),
				accessToken: Redacted.value(request.accessToken),
			}),
		catch: (cause) =>
			new VendorRequestError({
				operation: 'sendVendorRequest',
				message: 'vendor request failed',
				cause,
			}),
	})

	yield* Effect.annotateCurrentSpan({
		'user.id': request.userId,
		'vendor.response_status': response.status,
	})

	return response
})
```

Never log, throw, serialize, annotate, or return `Redacted.value(...)` unless the destination is explicitly meant to receive plaintext.

## Telemetry-Safe Attributes

Use stable non-sensitive identifiers, counts, booleans, domains, or keyed hashes instead of plaintext.

```typescript
const hashForTelemetry = Effect.fn('telemetry.hash-sensitive-value')(function* (value: string) {
	const secret = yield* Config.redacted('TELEMETRY_HASH_SECRET')
	return createHmac('sha256', Redacted.value(secret)).update(value).digest('hex')
})

export const annotateOutreachRecipient = Effect.fn('outreach.annotate-recipient')(function* (params: {
	userId: string
	recipientEmail: Redacted.Redacted
}) {
	const emailHash = yield* hashForTelemetry(Redacted.value(params.recipientEmail))

	yield* Effect.annotateCurrentSpan({
		'user.id': params.userId,
		'recipient.email_hash': emailHash,
	})
})
```

Do not use plain SHA hashes for sensitive values that have small search spaces. Use a keyed HMAC or avoid emitting the attribute.

## Error Messages

Error messages should name the failed operation without leaking sensitive inputs.

```typescript
export class OAuthRefreshError extends Data.TaggedError('OAuthRefreshError')<{
	readonly provider: 'google' | 'outlook'
	readonly userId: string
	readonly message: string
	readonly cause?: unknown
}> {}
```

Avoid fields like `token`, `authorizationHeader`, `emailBody`, `rawPayload`, `refreshToken`, or `decryptedValue` in tagged errors. Store safe metadata only.
