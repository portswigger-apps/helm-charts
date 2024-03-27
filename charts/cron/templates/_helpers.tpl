{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "cron.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
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
app.kubernetes.io/app: {{ template "cron.name" . }}
app.kubernetes.io/instance: {{ .Chart.Name }}-{{ template "cron.name" . }}
{{- end }}


{{/*
Common labels for all resources
*/}}
{{- define "cron.labels" -}}
{{ include "cron.labelselector" . }}
app.kubernetes.io/part-of: {{ template "cron.name" . }}
app.kubernetes.io/managed-by: Helm
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
