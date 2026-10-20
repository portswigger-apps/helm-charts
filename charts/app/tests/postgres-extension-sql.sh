#!/usr/bin/env bash
# Requires Helm 3, Docker and the chart dependencies. Disposable database only.
set -euo pipefail
cd "$(dirname "$0")/../../.."
image='pgvector/pgvector:0.8.1-pg16@sha256:33198da2828a14c30348d2ccb4750833d5ed9a44c88d840a0e523d7417120337'
# Disabled setup must not affect any rendered resource, even with configuration present.
default=$(helm template sql-test charts/app)
disabled=$(helm template sql-test charts/app --set postgresExtensionSetup.enabled=false \
  --set 'postgresExtensionSetup.extensions[0].name=vector' \
  --set-string 'postgresExtensionSetup.extensions[0].version=0.8.1')
[[ "$default" == "$disabled" ]] || { echo 'disabled render changed' >&2; exit 1; }
container="chart-extension-test-$$"
cleanup() { docker rm -f "$container" >/dev/null; }
sql=$(helm template sql-test charts/app --show-only templates/kubernetes/deployment.yaml \
  --set infra.postgres.enabled=true --set postgresExtensionSetup.enabled=true \
  --set 'postgresExtensionSetup.extensions[0].name=vector' \
  --set-string 'postgresExtensionSetup.extensions[0].version=0.8.1' |
  sed -n '/POSTGRES_EXTENSION_SQL_BEGIN/,/POSTGRES_EXTENSION_SQL_END/{ /POSTGRES_EXTENSION_SQL_/d; s/^            //; p; }')
[[ "$sql" == *'pg_advisory_xact_lock'* ]] || { echo 'rendered setup SQL missing' >&2; exit 1; }
docker run -d --name "$container" -e POSTGRES_PASSWORD=disposable "$image" >/dev/null
trap cleanup EXIT
for attempt in {1..60}; do
  if docker exec "$container" pg_isready -U postgres >/dev/null; then break; fi
  sleep 1
done
query() { docker exec -i "$container" psql -X -U postgres -v ON_ERROR_STOP=1 -At "$@"; }
setup_sql() { printf '%s\n' "$sql" | query; }
version() { query -c "SELECT extversion FROM pg_extension WHERE extname='vector'"; }
setup_sql
[[ $(version) == 0.8.1 ]]
setup_sql
[[ $(version) == 0.8.1 ]]
# Two simultaneous first installs must both succeed; no duplicate-object race.
query -c 'DROP EXTENSION vector' >/dev/null
setup_sql > /dev/null & first=$!
setup_sql > /dev/null & second=$!
wait "$first"
wait "$second"
[[ $(version) == 0.8.1 ]]
# A mismatch must not silently upgrade/downgrade the installed extension.
if failure=$(printf '%s\n' "${sql//0.8.1/0.7.4}" | query 2>&1); then
  echo 'wrong version unexpectedly accepted' >&2; exit 1
fi
[[ "$failure" == *'version mismatch: expected 0.7.4, installed 0.8.1'* ]]
[[ $(version) == 0.8.1 ]]
query -c 'DROP EXTENSION vector' >/dev/null
if failure=$(printf '%s\n' "${sql//vector/unavailable_extension}" | query 2>&1); then
  echo 'unavailable extension unexpectedly accepted' >&2; exit 1
fi
[[ "$failure" == *'extension "unavailable_extension" is not available'* ]]
[[ -z $(version) ]]
if failure=$(printf '%s\n' "${sql//0.8.1/99.99.99}" | query 2>&1); then
  echo 'unavailable version unexpectedly accepted' >&2; exit 1
fi
[[ "$failure" == *'version "99.99.99"'* ]]
[[ -z $(version) ]]
query -c 'CREATE ROLE unprivileged LOGIN; GRANT CONNECT ON DATABASE postgres TO unprivileged;' >/dev/null
if failure=$(printf '%s\n' "$sql" | docker exec -i "$container" psql -X -U unprivileged -d postgres -v ON_ERROR_STOP=1 2>&1); then
  echo 'unprivileged extension setup unexpectedly succeeded' >&2; exit 1
fi
[[ "$failure" == *'permission denied to create extension "vector"'* ]]
[[ -z $(version) ]]
# A later failure must roll back an earlier successful extension in the same request.
multi_sql=$(helm template sql-test charts/app --show-only templates/kubernetes/deployment.yaml \
  --set infra.postgres.enabled=true --set postgresExtensionSetup.enabled=true \
  --set 'postgresExtensionSetup.extensions[0].name=vector' \
  --set-string 'postgresExtensionSetup.extensions[0].version=0.8.1' \
  --set 'postgresExtensionSetup.extensions[1].name=unavailable_extension' \
  --set-string 'postgresExtensionSetup.extensions[1].version=1.0' |
  sed -n '/POSTGRES_EXTENSION_SQL_BEGIN/,/POSTGRES_EXTENSION_SQL_END/{ /POSTGRES_EXTENSION_SQL_/d; s/^            //; p; }')
if failure=$(printf '%s\n' "$multi_sql" | query 2>&1); then
  echo 'partially unsupported setup unexpectedly succeeded' >&2; exit 1
fi
[[ "$failure" == *'extension "unavailable_extension" is not available'* ]]
[[ -z $(version) ]]
# Waiting for another initializer is bounded, and failure leaves no extension.
query -c 'BEGIN; SELECT pg_advisory_xact_lock(1936748404, 1702392947); SELECT pg_sleep(5); COMMIT;' >/dev/null & holder=$!
for attempt in {1..50}; do
  [[ $(query -c "SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND classid=1936748404 AND objid=1702392947 AND granted") == 1 ]] && break
  sleep 0.1
done
[[ $(query -c "SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND classid=1936748404 AND objid=1702392947 AND granted") == 1 ]]
if failure=$(printf '%s\n' "$sql" | docker exec -i -e 'PGOPTIONS=-c lock_timeout=200 -c statement_timeout=1000' "$container" psql -X -U postgres -v ON_ERROR_STOP=1 2>&1); then
  echo 'advisory lock wait unexpectedly succeeded' >&2; exit 1
fi
[[ "$failure" == *'canceling statement due to lock timeout'* ]]
wait "$holder"
[[ -z $(version) ]]
echo 'PASS: first install, repeat, concurrent install, version fence, unavailable extension/version, privilege refusal, transaction rollback, lock timeout'
