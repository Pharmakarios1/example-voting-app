
{{/*
Return the chart name.
*/}}
{{- define "voting-app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Return the full Kubernetes resource name.
*/}}
{{- define "voting-app.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "voting-app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Common labels for resources.
*/}}
{{- define "voting-app.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") }}
app.kubernetes.io/name: {{ include "voting-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for each component.
Usage: include "voting-app.selectorLabels" (dict "root" . "component" "vote")
*/}}
{{- define "voting-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "voting-app.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}
