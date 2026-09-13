{{- define "langgraph-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "langgraph-agent.fullname" -}}
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

{{- define "langgraph-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "langgraph-agent.labels" -}}
helm.sh/chart: {{ include "langgraph-agent.chart" . }}
{{ include "langgraph-agent.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: agent
{{- end }}

{{- define "langgraph-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "langgraph-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "langgraph-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "langgraph-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "langgraph-agent.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}

{{- define "langgraph-agent.secretName" -}}
{{- printf "%s-secrets" (include "langgraph-agent.fullname" .) }}
{{- end }}

{{- define "langgraph-agent.createSecret" -}}
{{- if .Values.llm.apiKey }}true{{- end }}
{{- end }}
