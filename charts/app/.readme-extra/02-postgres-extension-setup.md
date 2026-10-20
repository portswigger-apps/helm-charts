## PostgreSQL extension setup

Extension setup is disabled by default. Enable it only when the database already
provides the requested extension files and the existing connection role can create
that extension. The chart does not grant permissions or install server-side files.

```yaml
infra:
  postgres:
    enabled: true
postgresExtensionSetup:
  enabled: true
  extensions:
    - name: vector
      version: "0.8.1"
```

The initializer uses the chart's existing PostgreSQL connection secret and runs
before custom init containers, application startup and configured pre-deploy or
pre-rollback commands. Concurrent pods serialize setup with a transaction advisory
lock in the same database. An absent extension is created at the explicit version;
an installed extension must match exactly. Setup never upgrades or removes an
extension. All requested extensions are checked in one transaction, and any error
rolls back the operation. Rollbacks therefore also require the configured version
to match the database; manage extension upgrades separately.

A failed initializer blocks the application or hook command. Inspect the
`postgres-extension-setup` init-container status and logs for connection,
unavailable-extension, privilege or version-mismatch errors. Successful logs name
the verified extensions and versions. Connection, statement and lock waits are
bounded per attempt; Kubernetes retries failed initializers. Database readiness
and secret provisioning must complete before setup can succeed.

Existing pre-deploy hooks run before ordinary release resources on first install.
If a database or its secret is created by that same release, do not configure a
pre-deploy command that depends on it: provision the database first, or use
application startup migrations. This initializer does not change Helm hook order.

The default client uses TLS `require`, which encrypts traffic without verifying
server identity. For `verify-ca` or `verify-full`, supply an immutable client image
with the database CA certificate at libpq's trusted-root location for UID 1000.
Client images must support non-root execution with a read-only filesystem. No
credentials or connection URLs belong in extension setup values.

To run the disposable PostgreSQL SQL checks locally (Helm 3, Docker and built chart
dependencies required):

```sh
bash charts/app/tests/postgres-extension-sql.sh
```
