{{- define "mcp-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcp-service.fullname" -}}
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

{{- define "mcp-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcp-service.labels" -}}
helm.sh/chart: {{ include "mcp-service.chart" . }}
{{ include "mcp-service.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: mcp-adapter
{{- end }}

{{- define "mcp-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mcp-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "mcp-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mcp-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "mcp-service.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{/*
The legacy service URL: explicit if given, otherwise derived from the legacy
release name and this release's namespace. This is the ONLY way this pod
reaches core banking data (spec section 1.4).
*/}}
{{- define "mcp-service.legacyUrl" -}}
{{- if .Values.legacy.serviceUrl }}
{{- .Values.legacy.serviceUrl | trimSuffix "/" }}
{{- else }}
{{- printf "http://%s.%s.svc.cluster.local:%v" .Values.legacy.legacyReleaseName .Release.Namespace .Values.legacy.port }}
{{- end }}
{{- end }}

{{- define "mcp-service.secretName" -}}
{{- if .Values.legacy.existingSecret }}
{{- .Values.legacy.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "mcp-service.fullname" .) }}
{{- end }}
{{- end }}
