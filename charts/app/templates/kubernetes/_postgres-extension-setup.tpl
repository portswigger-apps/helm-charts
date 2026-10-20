{{/* vim: set filetype=mustache: */}}

{{/*
Outputs the PostgreSQL extension setup init container.
*/}}
{{- define "app.postgresExtensionSetup" -}}
{{- $setup := .Values.postgresExtensionSetup -}}
{{- if $setup.enabled -}}
{{- if not .Values.infra.postgres.enabled }}{{ fail "postgresExtensionSetup requires infra.postgres.enabled" }}{{ end -}}
{{- if or (not (kindIs "slice" $setup.extensions)) (eq (len $setup.extensions) 0) }}{{ fail "postgresExtensionSetup.extensions must be a nonempty list" }}{{ end -}}
{{- $seen := dict -}}
{{- range $setup.extensions -}}
{{- if not (kindIs "map" .) }}{{ fail "postgresExtensionSetup.extensions entries must contain name and version" }}{{ end -}}
{{- if not (regexMatch "^[a-z][a-z0-9_]{0,62}$" (toString (.name | default ""))) }}{{ fail "invalid postgresExtensionSetup extension name" }}{{ end -}}
{{- if not (kindIs "string" .version) }}{{ fail "invalid postgresExtensionSetup extension version" }}{{ end -}}
{{- if not (regexMatch "^[0-9][A-Za-z0-9_.+-]{0,63}$" .version) }}{{ fail "invalid postgresExtensionSetup extension version" }}{{ end -}}
{{- if hasKey $seen .name }}{{ fail "duplicate postgresExtensionSetup extension name" }}{{ end -}}
{{- $_ := set $seen .name true -}}
{{- end -}}
{{- range $key, $maximum := dict "connectTimeoutSeconds" 120 "statementTimeoutMs" 300000 "lockTimeoutMs" 300000 -}}
{{- $value := get $setup $key -}}
{{- if or (not (regexMatch "^[1-9][0-9]*$" (toString $value))) (gt (int64 $value) (int64 $maximum)) }}{{ fail (printf "postgresExtensionSetup.%s must be an integer from 1 to %d" $key $maximum) }}{{ end -}}
{{- end -}}
{{- if not (has $setup.sslMode (list "disable" "require" "verify-ca" "verify-full")) }}{{ fail "postgresExtensionSetup.sslMode must be disable, require, verify-ca or verify-full" }}{{ end -}}
{{- if not (regexMatch "^[^[:space:]@]+@sha256:[a-f0-9]{64}$" $setup.image) }}{{ fail "postgresExtensionSetup.image must use an immutable sha256 digest" }}{{ end -}}
- name: postgres-extension-setup
  image: {{ $setup.image | quote }}
  imagePullPolicy: IfNotPresent
  command: [/bin/sh, -ec]
  args:
    - |
      psql -X --no-password --quiet --set=ON_ERROR_STOP=1 --tuples-only --no-align <<'POSTGRES_EXTENSION_SQL_END'
      -- POSTGRES_EXTENSION_SQL_BEGIN
      BEGIN;
      SELECT pg_advisory_xact_lock(1936748404, 1702392947);
      {{- range $setup.extensions }}
      DO $extension_setup$
      DECLARE installed_version text;
      BEGIN
        SELECT extversion INTO installed_version FROM pg_extension WHERE extname = '{{ .name }}';
        IF installed_version IS NULL THEN
          EXECUTE format('CREATE EXTENSION %I VERSION %L', '{{ .name }}', '{{ .version }}');
        ELSIF installed_version <> '{{ .version }}' THEN
          RAISE EXCEPTION 'Extension % version mismatch: expected %, installed %', '{{ .name }}', '{{ .version }}', installed_version;
        END IF;
        SELECT extversion INTO installed_version FROM pg_extension WHERE extname = '{{ .name }}';
        IF installed_version IS DISTINCT FROM '{{ .version }}' THEN
          RAISE EXCEPTION 'Extension % version verification failed', '{{ .name }}';
        END IF;
      END
      $extension_setup$;
      {{- end }}
      COMMIT;
      {{- range $setup.extensions }}
      SELECT 'Extension {{ .name }} ready at version {{ .version }}';
      {{- end }}
      POSTGRES_EXTENSION_SQL_END
      echo 'PostgreSQL extension setup complete'
  env:
    - name: PGDATABASE
      value: app
    {{- range $entry := list (dict "env" "PGHOST" "key" "host") (dict "env" "PGPORT" "key" "port") (dict "env" "PGUSER" "key" "username") (dict "env" "PGPASSWORD" "key" "password") }}
    - name: {{ $entry.env }}
      valueFrom:
        secretKeyRef:
          name: {{ include "app.postgresConnectionSecretName" $ }}
          key: {{ $entry.key }}
    {{- end }}
    - name: PGCONNECT_TIMEOUT
      value: {{ $setup.connectTimeoutSeconds | quote }}
    - name: PGOPTIONS
      value: {{ printf "-c statement_timeout=%v -c lock_timeout=%v" $setup.statementTimeoutMs $setup.lockTimeoutMs | quote }}
    - name: PGSSLMODE
      value: {{ $setup.sslMode | quote }}
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsUser: 1000
    capabilities:
      drop: [ALL]
  resources:
    requests:
      cpu: 10m
      memory: 32Mi
    limits:
      memory: 128Mi
{{- end -}}
{{- end -}}
