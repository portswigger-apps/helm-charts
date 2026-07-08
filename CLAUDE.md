# CLAUDE.md — helm-charts

Shared Helm "monocharts" (`app`, `cron`, `infra`) for the platform. Every product
in the org can depend on these — changes are broad-blast-radius by design.

## Before every commit in this repo

Run `pre-commit run --all-files` (after a one-time `pre-commit install` —
see README "Getting started"). **This is not enforced by CI or by git itself** —
it's a local hook, trivially skipped, and nothing currently catches drift on
merge. Skipping it has landed stale docs for real: the `app` chart's README
version badge sat wrong across three releases before anyone noticed
(portswigger-apps/helm-charts#37, #38, #39).

Specifically, `helm-docs` regenerates each chart's README from its
`values.yaml` comments (`# key -- description`, `@section` tags), using the
exact invocation in `.pre-commit-config.yaml`:

```
helm-docs --chart-search-root=charts --template-files=./README.md.gotmpl --sort-values-order=file
```

**Never hand-edit a chart README, and never run bare `helm-docs` without those
flags** — the default invocation alphabetizes/reformats and misplaces
`@section`-tagged fields relative to what's actually committed.

## Versioning

Bump `version` (and usually `appVersion`) in the chart's own `Chart.yaml` for
every user-visible change. `chart-releaser` only publishes a new release when
the version changes (`CR_SKIP_EXISTING: true` in `.github/workflows/test-and-release.yaml`
silently no-ops otherwise) — a change with no version bump never reaches
consumers, however correct the diff.

## Testing

- `helm lint charts/<chart>/`
- `helm unittest --strict charts/*/` — needs the `helm-unittest` plugin
  (`helm plugin install https://github.com/helm-unittest/helm-unittest`), not
  installed by default.

Both run in CI (`.github/workflows/test-and-release.yaml`) on every PR; neither
substitutes for `pre-commit` — they don't check README freshness at all.
