{{/* vim: set filetype=mustache: */}}


{{/*
Name to use for everything. The release name. No overrides, no .Chart.Name nonsense.
*/}}
{{- define "infra.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name to use for aws resources. MUST start with the namespace (product) name
*/}}
{{- define "infra.aws.name" -}}
{{- if hasPrefix .Release.Namespace .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Namespace .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
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

{{/*
Secret value used to authenticate CloudFront with the origin
*/}}
{{- define "app.cloudfrontSecretValue" -}}
{{- .Values.global.ingress.host | sha256sum }}
{{- end -}}

{{/*
Fetch given field from existing secret or generate a new random value
*/}}
{{- define "infra.fetchOrCreateSecretField" -}}
{{- $context := index . 0 -}}
{{- $secretName := index . 1 -}}
{{- $secretFieldName := index . 2 -}}

{{- $secretObj := (lookup "v1" "Secret" $context.Release.Namespace $secretName) | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $secretFieldValue := (get $secretData $secretFieldName) | default (randAlphaNum 20 | b64enc) }}
{{- $secretFieldValue -}}
{{- end -}}


{{/*
Returns the managed cache policy id based on policy name
*/}}
{{- define "infra.cloudfrontRouter.cachePolicyId" -}}
{{- $policyName := . -}}
{{- $cachePolicies := dict "CachingDisabled" "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" -}}
{{- $_ := set $cachePolicies "CachingOptimized" "658327ea-f89d-4fab-a63d-7e88639e58f6" -}}
{{- $_ := set $cachePolicies "CachingOptimizedForUncompressedObjects" "b2884449-e4de-46a7-ac36-70bc7f1ddd6d" -}}
{{- $_ := set $cachePolicies "UseOriginCacheControlHeaders" "83da9c7e-98b4-4e11-a168-04f0df8e2c65" -}}
{{- $_ := set $cachePolicies "UseOriginCacheControlHeaders-QueryStrings" "4cc15a8a-d715-48a4-82b8-cc0b614638fe" -}}
{{- if hasKey $cachePolicies $policyName -}}
{{ get $cachePolicies $policyName }}
{{- else -}}
{{ fail (printf "%s is not a recognised cache policy name." $policyName)}}
{{- end -}}
{{- end -}}

{{/*
Returns the origins with default values
*/}}
{{- define "infra.cloudfrontRouter.origins" -}}
{{- $routerOrigins := . -}}

{{- end -}}

{{/*
Returns the origins with default values
*/}}
{{- define "infra.cloudfrontRouter.default" -}}
{{- $routerDefault := . -}}

{{- end -}}