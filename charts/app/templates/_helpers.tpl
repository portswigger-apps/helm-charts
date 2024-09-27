{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "app.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name to use for aws resources. MUST start with the namespace (product) name
*/}}
{{- define "app.aws.name" -}}
{{- if hasPrefix .Release.Namespace .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Namespace .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Shared labels used for selector*/}}
{{/* This is an immutable field: this should not change between upgrade */}}
{{- define "app.labelselector" -}}
app.kubernetes.io/app: {{ template "app.name" . }}
app.kubernetes.io/instance: {{ .Chart.Name }}-{{ template "app.name" . }}
{{- end }}


{{/*
Common labels for all resources
*/}}
{{- define "app.labels" -}}
{{ include "app.labelselector" . }}
app.kubernetes.io/version: {{ quote .Values.image.tag }}
app.kubernetes.io/part-of: {{ template "app.name" . }}
app.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ template "app.chart" . }}
{{- end -}}


{{/*
Renders a value that contains template.
Usage:
{{ include "app.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "app.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}


{{/*
The name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.enabled }}
{{- default ( include "app.name" . ) .Values.global.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.global.serviceAccount.name }}
{{- end }}
{{- end -}}


{{/*
The name of the service account to use
*/}}
{{- define "app.serviceAccountAnnotations" -}}
{{- range $k, $v := .Values.global.serviceAccount.annotations }}
{{ $k }}: {{ $v }}
{{- end }}
{{- if and .Values.global.aws.accountId (or .Values.infra.s3Bucket.enabled .Values.infra.bedrock.enabled) }}
eks.amazonaws.com/role-arn: arn:aws:iam::{{- .Values.global.aws.accountId }}:role/product-roles/{{ include "app.aws.name" . }}-irsarole
{{- end }}
{{- end -}}


{{/*
Name of the secret that stores postgres connection details
*/}}
{{- define "app.postgresConnectionSecretName" -}}
{{ default (include "app.aws.name" . ) .Values.infra.postgres.nameOverride }}-postgres
{{- end -}}

{{/*
Postgres connection secret env variables
*/}}
{{- define "app.postgresConnectionSecretEnv" -}}
{{- if .Values.infra.postgres.enabled -}}
- name: DATABASE_NAME
  value: app
- name: DATABASE_HOST
  valueFrom:
    secretKeyRef:
      name: {{ include "app.postgresConnectionSecretName" . }}
      key: host
- name: DATABASE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "app.postgresConnectionSecretName" . }}
      key: port
- name: DATABASE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "app.postgresConnectionSecretName" . }}
      key: username
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "app.postgresConnectionSecretName" . }}
      key: password
- name: DATABASE_URL
  value: "postgres://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)"
- name: JDBC_DATABASE_URL
  value: "jdbc:postgresql://$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)?user=$(DATABASE_USERNAME)&password=$(DATABASE_PASSWORD)"
{{- end -}}
{{- end -}}

{{/*
Name of the secret that stores s3Bucket connection details
*/}}
{{- define "app.s3BucketConnectionSecretName" -}}
{{ default (include "app.aws.name" . ) .Values.infra.s3Bucket.nameOverride }}-s3bucket
{{- end -}}

{{/*
s3Bucket connection secret env variables
*/}}
{{- define "app.s3BucketConnectionSecretEnv" -}}
{{- if .Values.infra.s3Bucket.enabled -}}
- name: S3_BUCKET_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "app.s3BucketConnectionSecretName" . }}
      key: id
- name: S3_BUCKET_URL
  value: "s3://$(S3_BUCKET_NAME)/"
{{- end -}}
{{- end -}}

{{/*
Ingress annotations
*/}}
{{- define "app.ingressAnnotations" -}}
{{- range $k, $v := .Values.global.ingress.annotations }}
{{ $k }}: {{ $v }}
{{- end }}
{{- if (eq .Values.global.ingress.className "traefik") }}
traefik.ingress.kubernetes.io/router.middlewares: {{ .Release.Namespace }}-{{ .Release.Name }}-chain@kubernetescrd
{{- end }}
{{- end -}}

{{/*
Name of the secret that stores redis connection details
*/}}
{{- define "app.redisConnectionSecretName" -}}
{{- (include "app.aws.name" . ) -}}-redis-connection
{{- end -}}

{{/*
Redis connection secret env variables
*/}}
{{- define "app.redisConnectionSecretEnv" -}}
{{- if .Values.infra.redis.enabled -}}
- name: REDIS_USERNAME
  value: {{ include "app.name" . -}}-redis
- name: REDIS_PORT
  value: "6379"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "app.name" . -}}-redis-credentials
      key: password
{{- if gt (int .Values.infra.redis.nodeGroups) 1}}
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "app.redisConnectionSecretName" . }}
      key: configurationEndpointAddress
{{- else }}
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "app.redisConnectionSecretName" . }}
      key: primaryEndpointAddress
- name: REDIS_READER_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "app.redisConnectionSecretName" . }}
      key: readerEndpointAddress
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Return the number of bytes given a value
following a base 2 or base 10 number system.
Input can be: b | B | k | K | m | M | g | G | Ki | Mi | Gi
Or number without suffix (then the number gets interpreted as bytes)
Usage:
{{ include "app.toBytes" .Values.path.to.the.Value }}
*/}}
{{- define "app.toBytes" -}}
    {{- $si := . -}}
    {{- if not (typeIs "string" . ) -}}
        {{- $si = int64 $si | toString -}}
    {{- end -}}
    {{- $bytes := 0 -}}
    {{- if or (hasSuffix "B" $si) (hasSuffix "b" $si) -}}
        {{- $bytes = $si | trimSuffix "B" | trimSuffix "b" | float64 | floor -}}
    {{- else if or (hasSuffix "K" $si) (hasSuffix "k" $si) -}}
        {{- $raw := $si | trimSuffix "K" | trimSuffix "k" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000) | floor -}}
    {{- else if or (hasSuffix "M" $si) (hasSuffix "m" $si) -}}
        {{- $raw := $si | trimSuffix "M" | trimSuffix "m" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000 1000) | floor -}}
    {{- else if or (hasSuffix "G" $si) (hasSuffix "g" $si) -}}
        {{- $raw := $si | trimSuffix "G" | trimSuffix "g" | float64 -}}
        {{- $bytes = mulf $raw (mul 1000 1000 1000) | floor -}}
    {{- else if hasSuffix "Ki" $si -}}
        {{- $raw := $si | trimSuffix "Ki" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024) | floor -}}
    {{- else if hasSuffix "Mi" $si -}}
        {{- $raw := $si | trimSuffix "Mi" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024 1024) | floor -}}
    {{- else if hasSuffix "Gi" $si -}}
        {{- $raw := $si | trimSuffix "Gi" | float64 -}}
        {{- $bytes = mulf $raw (mul 1024 1024 1024) | floor -}}
    {{- else if (mustRegexMatch "^[0-9]+$" $si) -}}
        {{- $bytes = $si -}}
    {{- else -}}
        {{- printf "\n%s is invalid SI quantity\nSuffixes can be: b | B | k | K | m | M | g | G | Ki | Mi | Gi or without any Suffixes" $si | fail -}}
    {{- end -}}
    {{- $bytes | int64 -}}
{{- end -}}