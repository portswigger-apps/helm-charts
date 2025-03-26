{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "cron.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name to use for aws resources. MUST start with the namespace (product) name
*/}}
{{- define "cron.aws.name" -}}
{{- if hasPrefix .Release.Namespace .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Namespace .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cron.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Shared labels used for selector*/}}
{{/* This is an immutable field: this should not change between upgrade */}}
{{- define "cron.labelselector" -}}
cron.kubernetes.io/cron: {{ template "cron.name" . }}
cron.kubernetes.io/instance: {{ .Chart.Name }}-{{ template "cron.name" . }}
{{- end }}


{{/*
Common labels for all resources
*/}}
{{- define "cron.labels" -}}
{{ include "cron.labelselector" . }}
cron.kubernetes.io/part-of: {{ template "cron.name" . }}
cron.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ template "cron.chart" . }}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "cron.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.enabled }}
{{- default (include "cron.name" .) .Values.global.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.global.serviceAccount.name }}
{{- end }}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "cron.serviceAccountAnnotations" -}}
{{- range $k, $v := .Values.global.serviceAccount.annotations }}
{{ $k }}: {{ $v }}
{{- end }}
{{- if and .Values.global.aws.accountId (or .Values.infra.s3Bucket.enabled .Values.infra.bedrock.enabled .Values.infra.eventing.producer.enabled .Values.infra.eventing.consumer.enabled) }}
eks.amazonaws.com/role-arn: arn:aws:iam::{{- .Values.global.aws.accountId }}:role/product-roles/{{ include "cron.serviceAccountName" . }}-irsarole
{{- end }}
{{- end -}}

{{/*
Name of the secret that stores postgres connection details
*/}}
{{- define "cron.postgresConnectionSecretName" -}}
{{ default (include "cron.aws.name" . ) .Values.infra.postgres.nameOverride }}-postgres
{{- end -}}

{{/*
Postgres connection secret env variables
*/}}
{{- define "cron.postgresConnectionSecretEnv" -}}
{{- if .Values.infra.postgres.enabled -}}
- name: DATABASE_NAME
  value: app
- name: DATABASE_HOST
  valueFrom:
    secretKeyRef:
      name: {{ include "cron.postgresConnectionSecretName" . }}
      key: host
- name: DATABASE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "cron.postgresConnectionSecretName" . }}
      key: port
- name: DATABASE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ include "cron.postgresConnectionSecretName" . }}
      key: username
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "cron.postgresConnectionSecretName" . }}
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
{{- define "cron.s3BucketConnectionSecretName" -}}
{{ default (include "cron.aws.name" . ) .Values.infra.s3Bucket.nameOverride }}-s3bucket
{{- end -}}

{{/*
s3Bucket connection secret env variables
*/}}
{{- define "cron.s3BucketConnectionSecretEnv" -}}
{{- if .Values.infra.s3Bucket.enabled -}}
- name: S3_BUCKET_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "cron.s3BucketConnectionSecretName" . }}
      key: id
- name: S3_BUCKET_URL
  value: "s3://$(S3_BUCKET_NAME)/"
{{- end -}}
{{- end -}}