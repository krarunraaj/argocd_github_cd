{{- define "banking-web-application.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "banking-web-application.fullname" -}}
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

{{- define "banking-web-application.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "banking-web-application.labels" -}}
helm.sh/chart: {{ include "banking-web-application.chart" . }}
{{ include "banking-web-application.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: banking-web-frontend
{{- end }}

{{- define "banking-web-application.selectorLabels" -}}
app.kubernetes.io/name: {{ include "banking-web-application.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "banking-web-application.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "banking-web-application.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "banking-web-application.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{- define "banking-web-application.secretName" -}}
{{- printf "%s-secrets" (include "banking-web-application.fullname" .) }}
{{- end }}

{{- define "banking-web-application.createSecret" -}}
{{- if .Values.legacy.apiKey }}true{{- end }}
{{- end }}
