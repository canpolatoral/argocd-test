{{- define "hello-world-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hello-world-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "hello-world-chart.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hello-world-chart.labels" -}}
app.kubernetes.io/name: {{ include "hello-world-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "hello-world-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hello-world-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
