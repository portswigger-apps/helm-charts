{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "app.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
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
{{- if .Values.infra.serviceAccount.enabled }}
{{- default (include "app.name" .) .Values.infra.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.infra.serviceAccount.name }}
{{- end }}
{{- end -}}


{{/*
Secret value used to authenticate CloudFront with the origin
*/}}
{{- define "app.cloudfrontSecretValue" -}}
{{- .Values.global.ingress.host | sha256sum }}
{{- end -}}
