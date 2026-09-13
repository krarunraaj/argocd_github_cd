{{/* Expand the name of the chart. */}}
{{- define "legacy-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully qualified app name. */}}
{{- define "legacy-service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "legacy-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "legacy-service.labels" -}}
helm.sh/chart: {{ include "legacy-service.chart" . }}
{{ include "legacy-service.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: banking-system-of-record
{{- end }}

{{- define "legacy-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "legacy-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "legacy-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "legacy-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "legacy-service.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{/* Name of the Secret holding the database URL / API key. */}}
{{- define "legacy-service.secretName" -}}
{{- if .Values.postgres.existingSecret }}
{{- .Values.postgres.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "legacy-service.fullname" .) }}
{{- end }}
{{- end }}

{{/* True when this release needs a Secret of its own. */}}
{{- define "legacy-service.createSecret" -}}
{{- if and (not .Values.postgres.existingSecret) (or .Values.postgres.databaseUrl .Values.apiKey) }}true{{- end }}
{{- end }}
