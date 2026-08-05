# Codex Security CLI Reference

Source: [openai/codex-security](https://github.com/openai/codex-security). Confirm current options with the CLI's `--help` output before running expensive or mutating operations.

## Requirements

- Node.js `22.13.0+` in the Node 22 line, Node 24, or Node 26
- Python 3.10 or later for deep scans, report finalization, validation, patching, and export
- Codex Security access

## Authentication

```bash
npx @openai/codex-security login
npx @openai/codex-security login --device-auth
npx @openai/codex-security login status
npx @openai/codex-security logout
```

CI may use `OPENAI_API_KEY` or `CODEX_API_KEY`. Never echo or persist those values. Select an available credential explicitly with `--auth chatgpt` or `--auth api-key` when needed.

## Scan

```bash
npx @openai/codex-security scan /path/to/repository
npx @openai/codex-security scan /path/to/repository --path src --path tests
npx @openai/codex-security scan /path/to/repository --working-tree
npx @openai/codex-security scan /path/to/repository --diff origin/main
npx @openai/codex-security scan /path/to/repository --dry-run
npx @openai/codex-security scan /path/to/repository --verbose
```

Store results outside the repository:

```bash
npx @openai/codex-security scan /path/to/repository \
  --output-dir /path/outside/repository/security-results
```

Deep scans trade additional time and model cost for iterative discovery:

```bash
npx @openai/codex-security scan /path/to/repository \
  --mode deep \
  --workers 2 \
  --subagents 0 \
  --stop-after-no-new 3 \
  --max-discovery-runs 10
```

Use `--max-cost <amount>` when a spending cap is required. Add `--knowledge-base <path>` for threat models, architecture documents, or security policies the user placed in scope.

## History And Comparison

```bash
npx @openai/codex-security scans list /path/to/repository
npx @openai/codex-security scans show SCAN_ID
npx @openai/codex-security scans rerun SCAN_ID
npx @openai/codex-security scans match BEFORE_SCAN_ID AFTER_SCAN_ID
npx @openai/codex-security scans compare BEFORE_SCAN_ID AFTER_SCAN_ID
```

Comparison classifies findings as new, persisting, reopened, resolved, or unknown. Missing findings remain unknown when later coverage is incomplete.

## Validate And Patch

```bash
npx @openai/codex-security validate /path/to/findings.json \
  "Possible SQL injection in src/query.ts:42"

npx @openai/codex-security patch /path/to/findings.json \
  "Missing authorization check in src/routes.ts:18"
```

Run `patch` from the intended repository only after the user authorizes code changes. Review every resulting change before testing or committing it.

## Export And CI

```bash
npx @openai/codex-security export /path/to/results \
  --export-format sarif \
  --output /path/to/results.sarif

npx @openai/codex-security scan /path/to/repository \
  --json \
  --fail-on-severity high
```

The documented exit codes are:

- `0`: completed report-only scan or passing severity policy
- `1`: completed scan whose findings violate the severity policy
- other nonzero values: runtime/export failures or process interruption; inspect CLI diagnostics

Use `install-hook` only when the user explicitly asks to add a pre-commit security scan.
