## PostgreSQL extensions

The platform can create extensions in the `app` database after PostgreSQL is
available. Set `postgres.extensions` on the chart that owns the `PostgresInstance`:

```yaml
postgres:
  enabled: true
  extensions:
    - name: vector
      version: "0.8.1"
    - name: pg_trgm
```

The default empty list omits `spec.extensions` and leaves existing instances
unchanged. Extension names and versions are validated by the platform API. Names
may include underscores and hyphens (for example, `pg_trgm` and `uuid-ossp`).
Versions must be quoted strings: write `"1.6"`, not `1.6`. Omitting a version uses
the default supplied by the database engine.

The platform adopts extensions that already exist. Changing a configured version
does not upgrade an installed extension or enforce its current version; upgrades
require a separately managed `ALTER EXTENSION ... UPDATE`. Removing an entry or
deleting the claim does not drop the extension (`deletionPolicy: Orphan`).

This requires a platform with `PostgresInstance.spec.extensions` support and the
PostgreSQL SQL provider installed. Provisioning is asynchronous: a chart install
or dependency update does not ensure extensions are ready before application
startup or Helm hooks. Verify provisioning and the actual installed version
before rolling out extension-dependent migrations.

With `postgres.create: false`, this chart does not manage the database claim or
its extensions. Configure them on the claim managed elsewhere; for a shared
instance, its owner manages the extension list once for that database.
