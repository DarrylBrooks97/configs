# Effect Caller Boundaries

Use this reference when wiring Effect programs into normal TypeScript callers, Inngest, Elysia/API routes, cron jobs, scripts, or other server-side entry points.

## Boundary Principle

Effect is an implementation model for complex server-side logic. It should not leak into ordinary call sites unless the caller is itself inside another Effect program.

- Normal TypeScript callers should see `async`/`Promise` functions and call them with `await`.
- Effect callers should see/call Effect programs and compose them with `yield*`.
- `Effect.runPromise`, `Effect.provide`, live layer composition, and final failure mapping belong in thin adapters, not scattered through business callers.

## Export A Promise Facade For Normal Callers

Keep the Effect program internal or clearly marked as internal, then export a normal async function for route/job/script code.

```typescript
const configureIntegrationEffect = Effect.fn('integrations.configure')(function* (params: ConfigureParams) {
	const service = yield* IntegrationConfigService
	return yield* service.configure(params)
})

export async function configureIntegration(params: ConfigureParams): Promise<ConfigureResult> {
	return await Effect.runPromise(Effect.provide(configureIntegrationEffect(params), IntegrationConfigLive))
}
```

Normal callers should look like ordinary TypeScript:

```typescript
const result = await configureIntegration(params)
```

They should not need to import `Effect`, know which layers to provide, or understand `Effect.Effect<Success, Error, Context>`.

## Compose Directly Inside Effect Programs

When the caller is already an Effect program, do not bounce through the Promise facade. Compose the underlying Effect function directly.

```typescript
const provisionWorkspaceEffect = Effect.fn('workspace.provision')(function* (params: ProvisionParams) {
	const integration = yield* configureIntegrationEffect(params.integration)
	const workspace = yield* createWorkspaceEffect({
		userId: params.userId,
		integrationId: integration.id,
	})

	return { integration, workspace }
})
```

Use this shape for shared orchestration, workflows that compose several Effect services, and tests that assert typed failure channels.

## Inngest

Keep handlers thin. Each durable step should call a normal async facade unless the step body itself is intentionally an Effect orchestration.

```typescript
export const crmSyncWorkflow = inngest.createFunction(
	{ id: 'crm-sync' },
	{ event: 'workflows/crm.sync' },
	async ({ event, step }) =>
		step.run('sync account', async () => await syncCrmAccount(event.data))
)
```

The facade owns the Effect runtime details:

```typescript
const syncCrmAccountEffect = Effect.fn('crm-sync.sync-account')(function* (params: SyncParams) {
	const service = yield* CrmSyncService
	return yield* service.syncAccount(params)
})

export async function syncCrmAccount(params: SyncParams): Promise<SyncResult> {
	return await Effect.runPromise(
		Effect.provide(syncCrmAccountEffect(params), [CrmSyncLive, CrmSyncTelemetryLive, DatabaseLive])
	)
}
```

If a workflow has multiple durable steps, each step should call a focused facade. Do not hide many durable operations inside one large anonymous handler.

## API Routes

Route handlers should parse/authenticate request state, call one normal async facade, and convert returned outcomes or thrown boundary errors to HTTP responses.

```typescript
try {
	const result = await configureIntegration(params)
	return { ok: true as const, integration: result }
} catch (error) {
	return mapConfigureIntegrationErrorToResponse(error)
}
```

If the route boundary needs typed Effect failure mapping, keep it inside the facade or a route-local adapter function, not in every caller. Match on the error value: use `_tag` first, then fields that change behavior.

```typescript
const mapConfigureFailureToRouteResult = (error: ConfigureIntegrationError): Effect.Effect<RouteResult> => {
	switch (error._tag) {
		case 'InvalidIntegrationConfigError':
			return Effect.succeed({
				status: 400,
				body: { ok: false as const, field: error.field, message: error.message },
			})

		case 'IntegrationProviderUnavailableError':
			return Effect.succeed({
				status: error.retryAfter ? 503 : 502,
				body: { ok: false as const, retryAfter: error.retryAfter },
			})
	}
}

export async function configureIntegrationForRoute(params: ConfigureParams): Promise<RouteResult> {
	const resultEffect = Effect.matchEffect(configureIntegrationEffect(params), {
		onSuccess: (result) => Effect.succeed({ status: 200, body: { ok: true as const, integration: result } }),
		onFailure: mapConfigureFailureToRouteResult,
	})

	return await Effect.runPromise(Effect.provide(resultEffect, IntegrationConfigLive))
}
```

## Running With Exits

Use `Effect.runPromiseExit` inside boundary adapters only when that adapter needs to inspect the full failure cause.

```typescript
export async function syncCrmAccountWithLogging(params: SyncParams): Promise<SyncResult> {
	const exit = await Effect.runPromiseExit(Effect.provide(syncCrmAccountEffect(params), [CrmSyncLive, DatabaseLive]))

	if (Exit.isFailure(exit)) {
		logger.error('crm sync failed', {
			cause: Cause.pretty(exit.cause),
			userId: params.userId,
		})
	}

	return Exit.match(exit, {
		onSuccess: (result) => result,
		onFailure: (cause) => {
			throw new CrmSyncBoundaryError({ message: 'crm sync failed', cause })
		},
	})
}
```

Do not include secrets or raw PII in logged cause context. Use redacted or hashed attributes.
