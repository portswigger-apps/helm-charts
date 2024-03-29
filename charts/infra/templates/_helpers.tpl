{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "infra.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "infra.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Shared labels used for selector*/}}
{{/* This is an immutable field: this should not change between upgrade */}}
{{- define "infra.labelselector" -}}
app.kubernetes.io/app: {{ template "infra.name" . }}
app.kubernetes.io/instance: {{ .Chart.Name }}-{{ template "infra.name" . }}
{{- end }}


{{/*
Common labels for all resources
*/}}
{{- define "infra.labels" -}}
{{ include "infra.labelselector" . }}
app.kubernetes.io/part-of: {{ template "infra.name" . }}
app.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ template "infra.chart" . }}
{{- end -}}
