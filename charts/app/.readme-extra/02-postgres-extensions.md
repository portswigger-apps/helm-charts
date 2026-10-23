## PostgreSQL extensions

Configure platform-managed extensions through the infra chart dependency:

```yaml
infra:
  postgres:
    enabled: true
    extensions:
      - name: vector
        version: "0.8.1"
      - name: pg_trgm
```

The platform creates extensions in the `app` database after PostgreSQL becomes
available. The default empty list leaves existing instances unchanged. Names
may include underscores and hyphens, such as `pg_trgm` and `uuid-ossp`.
Versions must be quoted strings (`"1.6"`, not `1.6`); omitting a version uses
the database engine's default. The platform API validates names and versions.

Existing extensions are adopted as-is. Changing the configured version does not
upgrade an installed extension or enforce its current version. Upgrades require
a separately managed `ALTER EXTENSION ... UPDATE`. Removing an entry or deleting
the claim does not drop the extension (`deletionPolicy: Orphan`).

This requires platform support for `PostgresInstance.spec.extensions` and the
PostgreSQL SQL provider. Extension creation is asynchronous and does not run in
application init containers or Helm hooks. First apply the extension
configuration with an application version that works without it, verify
provisioning and the actual installed version, then deploy extension-dependent
migrations and application code. Helm does not wait for extension provisioning
before starting pods or running pre-install/pre-upgrade hooks. On first install,
those hooks also run before ordinary database and secret resources are created.

With `infra.postgres.create: false`, configure extensions on the claim managed
elsewhere; setting this list does not change that external claim. Shared-instance
extensions belong to the owner of that database claim.
