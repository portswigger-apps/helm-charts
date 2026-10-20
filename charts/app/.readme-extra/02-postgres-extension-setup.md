## PostgreSQL extension setup

Setup is disabled by default. It uses the existing PostgreSQL connection secret;
extension files must already exist on the server, and the connection role must
have permission to create them.

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

Setup runs before custom init containers, application startup, and configured
pre-deploy or pre-rollback commands. It creates a missing extension at the
requested version, fails if an installed version differs, and never upgrades.
If initialization fails, inspect the `postgres-extension-setup` init-container
status and logs; Kubernetes retries failed initializers.

On first install, Helm runs pre-deploy hooks before ordinary release resources.
If the same release creates the database or secret, dependent pre-deploy commands
cannot use them; provision the database first or use application startup
migrations.

TLS defaults to `require`, which encrypts traffic without verifying server
identity. For `verify-ca` or `verify-full`, use an immutable custom client image
with the database CA in its trusted roots; it must support UID 1000 and a
read-only filesystem.
