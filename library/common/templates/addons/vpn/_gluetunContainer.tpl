{{/*
The gluetun sidecar container to be inserted.
*/}}
{{- define "tc.v1.common.addon.vpn.gluetun.container" -}}
enabled: true
imageSelector: gluetunImage
probes:
  {{- if not $.Values.addons.vpn.probes -}}
    {{- $_ := set $.Values.addons.vpn "probes" dict -}}
  {{- end -}}
  {{- $livness := $.Values.addons.vpn.probes.liveness | default (dict "enabled" false) -}}
  {{- $readiness := $.Values.addons.vpn.probes.readiness | default (dict "enabled" false) -}}
  {{- $startup := $.Values.addons.vpn.probes.startup | default (dict "enabled" false) }}
  liveness:
    {{- $livness | toYaml | nindent 4 }}
  readiness:
    {{- $readiness | toYaml | nindent 4 }}
  startup:
    {{- $startup | toYaml | nindent 4 }}
resources:
  excludeExtra: true
securityContext:
  runAsUser: 0
  runAsNonRoot: false
  readOnlyRootFilesystem: false
  runAsGroup: 568
  capabilities:
    add:
      - NET_ADMIN
      - NET_RAW
      - MKNOD

env:
  DNS_KEEP_NAMESERVER: "on"
  DOT: "off"
{{- if $.Values.addons.vpn.killSwitch }}
{{- $excludednetworks := (printf "%v,%v" $.Values.chartContext.podCIDR $.Values.chartContext.svcCIDR) -}}
{{- range $.Values.addons.vpn.excludedNetworks_IPv4 -}}
  {{- $excludednetworks = (printf "%v,%v" $excludednetworks .) -}}
{{- end }}
{{- range $.Values.addons.vpn.excludedNetworks_IPv6 -}}
  {{- $excludednetworksv6 = (printf "%v,%v" $excludednetworks .) -}}
{{- end }}
  FIREWALL: "on"
  FIREWALL_OUTBOUND_SUBNETS: {{ $excludednetworks | quote }}
{{- $inputPorts := list -}}
{{- if and
  $.Values.service $.Values.service.main $.Values.service.main.ports
  $.Values.service.main.ports.main $.Values.service.main.ports.main.port -}}
  {{- $inputPorts = list $.Values.service.main.ports.main.port -}}
{{- end -}}
{{- $inputPorts = concat $inputPorts $.Values.addons.vpn.inputPorts | mustUniq }}
  FIREWALL_INPUT_PORTS: {{ join "," $inputPorts }}
{{- else }}
  FIREWALL: "off"
{{- end }}

{{- with $.Values.addons.vpn.env }}
  {{- . | toYaml | nindent 2 }}
{{- end -}}

{{- range $envList := $.Values.addons.vpn.envList -}}
  {{- if and $envList.name $envList.value }}
  {{ $envList.name }}: {{ $envList.value | quote }}
  {{- else -}}
    {{- fail "Please specify name/value for VPN environment variable" -}}
  {{- end -}}
{{- end -}}

{{- with $.Values.addons.vpn.args }}
args:
  {{- . | toYaml | nindent 2 }}
{{- end }}
{{- end -}}
