# helm-charts
Helm charts for deploying components to the shared platform.

## Getting started

You'll need the following installed:

 - Helm: https://helm.sh/docs/intro/install/#through-package-managers
 - Helm docs: https://github.com/norwoodj/helm-docs?tab=readme-ov-file#installation
 - Helm unittest plugin: https://github.com/helm-unittest/helm-unittest?tab=readme-ov-file#install
 - pre-commit: https://pre-commit.com/#install

Then, from the repo root, install the git hook so it runs automatically on every commit:

```sh
pre-commit install
```

Without this step `pre-commit` is just a config file — nothing runs it, and README drift
(stale version badges, missing/misplaced values) won't be caught until someone notices by eye.
CI does not currently run `pre-commit` either, so this is the only thing standing between a
values.yaml change and a stale README.

## Documentation

We use `helm-docs`, run via the `pre-commit` git hook installed above, to regenerate READMEs
with Helm chart values in a table. Run `pre-commit run --all-files` to regenerate on demand
(e.g. if you skipped installing the hook, or amended a commit with `--no-verify`).

## Unit tests

We make use of the `helm unittest` command to test the behaviour of our charts. These tests are not overly
exhaustive, but cover off the main, key functionality of each resource the chart.

## Chart dependencies

The `infra` chart is a dependency of the `app` and `cron` chart. This means that infrastructure can be created
or existing secrets can be mapped in using just those charts.

### Shared data

Where charts need to share some configuration, we make use of global values. For example, an `Ingress` needs
a `host` name, and a `CloudFrontSite` targets that host name as an origin, so the ingress section lives in `global`:

```yaml
global:
  ingress:
    host: "example.host.com"
```

The `infra` and `app` reference this value with: `{{ .Values.global.ingress.host }}`. Only the necessary global variables
are documented in `values.yaml`. For example, the `infra` chart only needs to know about the ingress host, it doesn't need to
know about paths, ports, annotations etc...

## Network policies and IP allowlists



## Other guidance

- **We don't use shared templates.** It is possible to reference helper functions across chart boundaries, but
this can lead to high coupling between charts and circular dependencies (`infra` using an `app.*` templates
and `app` using `infra.*` templates).

- **The `infra` chart must always be independently deployable.** This means that we could use it to deploy infrastructure
for a third-party Helm chart. For example, we could use it to deploy the database for a Ghost blog site.

- **Cross-cutting work must be broken down.** Where you have a change to make to expose a new piece of functionality
from the `infra` chart, the work needs to be broken up into two pieces:
  1. New functionality should be added to the `infra` chart, and should be complete. A new `infra` chart version must be deployed.
  2. The dependency in the `app` or `cron` chart should be bumped, new functionality exposed, and a new chart version released.
Imagine that the `infra` chart is developed by a third party and you are updating the dependent chart with the new functionality.

- **Explicitly hide values from documentation to discourage use.** Use the `# @ignored` comment to annotate values you don't want
to appear in the README. For example, `ciliumNetworkPolicy.enabled` allows you to disable the `CiliumNetworkPolicy` for an app, but
we don't want to encourage it. When someone thinks something might be hard, they are likely to disable it and copy that config
across all the apps that they create... `chmod 777 ...`, `sudo EVERYTHING`, `su root`, `service iptables stop`, `sudo setenforce Permissive`...

- **REMEMBER: These charts are public. Avoid exposing underlying service details in things like test data.**