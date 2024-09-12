{{/*
The gluetun sidecar container to be inserted.
*/}}
{{- define "tc.v1.common.addon.vpn.openvpn.container" -}}
enabled: true
imageSelector: openvpnImage
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
  runAsGroup: 0
  capabilities:
    add:
      - NET_ADMIN
      - NET_RAW
      - MKNOD
      - SYS_MODULE

env:
{{- with $.Values.addons.vpn.env }}
  {{- . | toYaml | nindent 2 }}
{{- end }}
  {{- if and $.Values.addons.vpn.openvpn.username $.Values.addons.vpn.openvpn.password }}
  VPN_AUTH: {{ (printf "%v;%v" $.Values.addons.vpn.openvpn.username $.Values.addons.vpn.openvpn.password) }}
  {{- end -}}
{{- if $.Values.addons.vpn.killSwitch }}
{{- $ipv4list := $.Values.addons.vpn.excludedNetworks_IPv4 }}

{{- if $.Values.chartContext.podCIDR }}
{{- $ipv4list = append $ipv4list $.Values.chartContext.podCIDR }}
{{- end }}
{{- if $.Values.chartContext.svcCIDR }}
{{- $ipv4list = append $ipv4list $.Values.chartContext.svcCIDR }}
{{- end }}

  FIREWALL: "ON"
  {{- range $index, $value := $ipv4list }}
  ROUTE_{{ add $index 1 }}: {{ $value | quote }}
  {{- end }}
{{- if $.Values.addons.vpn.excludedNetworks_IPv6 }}
  {{- $excludednetworksv6 := "" -}}
  {{- range $.Values.addons.vpn.excludedNetworks_IPv4 -}}
    {{- $excludednetworksv6 = ( printf "%v;%v" $excludednetworksv6 . ) -}}
  {{- end }}
  {{- range $index, $value := $.Values.addons.vpn.excludedNetworks_IPv6 }}
  ROUTE6_{{ add $index 1 }}: {{ $value | quote }}
  {{- end }}
{{- end }}
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
{{- end -}}
{{- end -}}
