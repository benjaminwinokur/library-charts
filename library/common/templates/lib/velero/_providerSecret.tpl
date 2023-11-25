{{- define "tc.v1.common.lib.velero.provider.secret" -}}
  {{- $rootCtx := .rootCtx }}
  {{- $objectData := .objectData -}}

  {{- $creds := "" -}} {{/* We can add additinal providers here, and only create the template for the data */}}

  {{/* Make sure provider is a string */}}
  {{- $provider := $objectData.provider | toString -}}

  {{- if and (eq $provider "aws") $objectData.credential.aws -}}
    {{- $creds = (include "tc.v1.common.lib.velero.provider.aws.secret" (dict "creds" $objectData.credential.aws) | fromYaml).data -}}
    {{/* Map provider */}}
    {{- $_ := set $objectData "provider" "velero.io/aws" -}}
  {{- end -}}

  {{/* If we matched a provider, create the secret */}}
  {{- if $creds -}}
    {{- $secretData := (dict
          "name" (printf "vsl-%s" $objectData.name)
          "labels" $objectData.labels
          "annotations" $objectData.annotations
          "data" (dict "cloud" $creds)
      ) -}}

    {{/* Create the secret */}}
    {{- include "tc.v1.common.class.secret" (dict "rootCtx" $rootCtx "objectData" $secretData) -}}

    {{/* Update the credential object with the name and key */}}
    {{- $_ := set $objectData.credential "name" (printf "vsl-%s" $objectData.name) -}}
    {{- $_ := set $objectData.credential "key" "cloud" -}}

  {{- end -}}

{{- end -}}
