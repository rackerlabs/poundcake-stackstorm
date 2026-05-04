{{- define "poundcakeStackstorm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "poundcakeStackstorm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "poundcakeStackstorm.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "poundcakeStackstorm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "poundcakeStackstorm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "poundcakeStackstorm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "poundcakeStackstorm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "poundcakeStackstorm.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormActionrunnerServiceAccountName" -}}
{{- $cfg := .Values.stackstormActionrunner | default dict -}}
{{- $serviceAccount := $cfg.serviceAccount | default dict -}}
{{- $name := $serviceAccount.name | default "" -}}
{{- $create := $serviceAccount.create | default true -}}
{{- if $create -}}
{{- default (printf "%s-stackstorm-actionrunner" (include "poundcakeStackstorm.fullname" .) | trunc 63 | trimSuffix "-") $name -}}
{{- else -}}
{{- default "default" $name -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormSubchartPrefix" -}}
{{- default "stackstorm" .Values.stackstorm.releaseName -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormApiUrl" -}}
{{- if .Values.stackstorm.url -}}
{{- .Values.stackstorm.url -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "http://%s-st2api:9101" (include "poundcakeStackstorm.stackstormSubchartPrefix" .) -}}
{{- else -}}
{{- printf "http://stackstorm-api:%v" .Values.services.stackstormApi.port -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormAuthUrl" -}}
{{- if .Values.stackstorm.authUrl -}}
{{- .Values.stackstorm.authUrl -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "http://%s-st2auth:9100" (include "poundcakeStackstorm.stackstormSubchartPrefix" .) -}}
{{- else -}}
{{- printf "http://stackstorm-auth:%v" .Values.services.stackstormAuth.port -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormStreamUrl" -}}
{{- if .Values.stackstorm.streamUrl -}}
{{- .Values.stackstorm.streamUrl -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "http://%s-st2stream:9102" (include "poundcakeStackstorm.stackstormSubchartPrefix" .) -}}
{{- else -}}
{{- printf "http://stackstorm-stream:%v" .Values.services.stackstormStream.port -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.apiServiceUrl" -}}
{{- printf "http://poundcake-api.%s.svc.cluster.local:%v" .Release.Namespace .Values.services.api.port -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormPodSecurityContext" -}}
{{- $base := deepCopy (.Values.podSecurityContext | default dict) -}}
{{- $override := .Values.stackstormPodSecurityContext | default dict -}}
{{- $merged := mergeOverwrite $base $override -}}
{{- if gt (len $merged) 0 -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.validateUniqueUrlServicePorts" -}}
{{- $urlServices := list
  (dict "name" "services.api.port" "port" (int .Values.services.api.port))
  (dict "name" "services.ui.port" "port" (int .Values.services.ui.port))
  (dict "name" "services.stackstormApi.port" "port" (int .Values.services.stackstormApi.port))
  (dict "name" "services.stackstormAuth.port" "port" (int .Values.services.stackstormAuth.port))
-}}
{{- if eq (include "poundcakeStackstorm.stackstormServiceEnabled" (dict "root" . "name" "stream")) "true" -}}
{{- $urlServices = append $urlServices (dict "name" "services.stackstormStream.port" "port" (int .Values.services.stackstormStream.port)) -}}
{{- end -}}
{{- if eq (include "poundcakeStackstorm.stackstormServiceEnabled" (dict "root" . "name" "web")) "true" -}}
{{- $urlServices = append $urlServices (dict "name" "services.stackstormWeb.port" "port" (int .Values.services.stackstormWeb.port)) -}}
{{- end -}}
{{- $seen := dict -}}
{{- range $service := $urlServices -}}
{{- $name := get $service "name" -}}
{{- $port := get $service "port" -}}
{{- $key := printf "%d" $port -}}
{{- if hasKey $seen $key -}}
{{- fail (printf "URL-addressable service ports must be unique. %s and %s both use port %d." (get $seen $key) $name $port) -}}
{{- end -}}
{{- $_ := set $seen $key $name -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormAuthSecretName" -}}
{{- if .Values.stackstorm.adminPasswordSecret -}}
{{- .Values.stackstorm.adminPasswordSecret -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "%s-st2-auth" (include "poundcakeStackstorm.stackstormSubchartPrefix" .) -}}
{{- else -}}
{{- printf "stackstorm-secrets" -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormApiKeySecret" -}}
{{- if .Values.stackstorm.apiKeySecretName -}}
{{- .Values.stackstorm.apiKeySecretName -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "%s-st2-apikeys" (include "poundcakeStackstorm.stackstormSubchartPrefix" .) -}}
{{- else -}}
{{- printf "stackstorm-apikeys" -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormApiKeySecretKey" -}}
{{- if .Values.stackstorm.apiKeySecretKey -}}
{{- .Values.stackstorm.apiKeySecretKey -}}
{{- else if .Values.stackstorm.releaseName -}}
{{- printf "api-key" -}}
{{- else -}}
{{- printf "st2_api_key" -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormPackConfigSecretName" -}}
{{- printf "stackstorm-pack-configs" -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormThirdPartyPacksEnabled" -}}
{{- $bootstrap := .Values.stackstorm.bootstrap | default dict -}}
{{- $packs := $bootstrap.packs | default dict -}}
{{- $kubernetes := $packs.kubernetes | default dict -}}
{{- $openstack := $packs.openstack | default dict -}}
{{- ternary "true" "false" (or ($kubernetes.enabled | default false) ($openstack.enabled | default false)) -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormSharedStorageEnabled" -}}
{{- ternary "true" "false" (.Values.persistence.stackstormSharedStorage.enabled | default false) -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormSharedStorageClassName" -}}
{{- $shared := .Values.persistence.stackstormSharedStorage | default dict -}}
{{- if ($shared.storageClassName | default "") -}}
{{- $shared.storageClassName -}}
{{- else if and (.Values.longhorn) (.Values.longhorn.rwxStorageClass) (.Values.longhorn.rwxStorageClass.create | default false) -}}
{{- .Values.longhorn.rwxStorageClass.name -}}
{{- else if .Values.persistence.storageClassName -}}
{{- .Values.persistence.storageClassName -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormThirdPartyPackConfigSecretEnabled" -}}
{{- $bootstrap := .Values.stackstorm.bootstrap | default dict -}}
{{- $packs := $bootstrap.packs | default dict -}}
{{- $openstack := $packs.openstack | default dict -}}
{{- $openstackConfig := $openstack.config | default dict -}}
{{- ternary "true" "false" (or (ne ($openstackConfig.cloudsYaml | default "") "") (ne ($openstackConfig.caCert | default "") "")) -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormThirdPartyPackInitContainer" -}}
- name: seed-stackstorm-pack-content
  image: {{ .Values.stackstormImage.repository }}:{{ .Values.stackstormImage.tag }}
  imagePullPolicy: {{ .Values.stackstormImage.pullPolicy }}
  securityContext:
    {{- toYaml .Values.utilitySecurityContext | nindent 4 }}
  command:
    - /bin/bash
    - -ec
    - |
      set -euo pipefail
      mkdir -p /mnt/stackstorm-shared/packs /mnt/stackstorm-shared/virtualenvs
      cp -Rn /opt/stackstorm/packs/. /mnt/stackstorm-shared/packs/
      if [ -d /opt/stackstorm/virtualenvs ]; then
        cp -Rn /opt/stackstorm/virtualenvs/. /mnt/stackstorm-shared/virtualenvs/ || true
      fi
  volumeMounts:
    - name: stackstorm-packs
      mountPath: /mnt/stackstorm-shared/packs
    - name: stackstorm-virtualenvs
      mountPath: /mnt/stackstorm-shared/virtualenvs
{{- end -}}

{{- define "poundcakeStackstorm.stackstormThirdPartyPackVolumeMounts" -}}
- name: stackstorm-pack-configs
  mountPath: /opt/stackstorm/configs
  readOnly: true
- name: stackstorm-packs
  mountPath: /opt/stackstorm/packs
- name: stackstorm-virtualenvs
  mountPath: /opt/stackstorm/virtualenvs
{{- end -}}

{{- define "poundcakeStackstorm.stackstormThirdPartyPackVolumes" -}}
- name: stackstorm-pack-configs
  secret:
    secretName: {{ include "poundcakeStackstorm.stackstormPackConfigSecretName" . }}
    optional: true
{{- if eq (include "poundcakeStackstorm.stackstormSharedStorageEnabled" .) "true" }}
- name: stackstorm-packs
  persistentVolumeClaim:
    claimName: stackstorm-packs
- name: stackstorm-virtualenvs
  persistentVolumeClaim:
    claimName: stackstorm-virtualenvs
{{- else }}
- name: stackstorm-packs
  emptyDir: {}
- name: stackstorm-virtualenvs
  emptyDir: {}
{{- end }}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormMongoName" -}}
{{- if .Values.stackstorm.resourceNames.mongodb -}}
{{- .Values.stackstorm.resourceNames.mongodb -}}
{{- else -}}
{{- printf "stackstorm-mongodb" -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.rabbitmqSecretName" -}}
{{- if .Values.rabbitmq.existingSecret -}}
{{- .Values.rabbitmq.existingSecret -}}
{{- else -}}
{{- printf "stackstorm-rabbitmq" -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.enabledPlugins" -}}
{{- $configured := .Values.config.enabledPlugins | default "dummy" -}}
{{- $configured -}}
{{- end -}}

{{- define "poundcakeStackstorm.databaseMode" -}}
{{- $database := .Values.database | default dict -}}
{{- $mode := $database.mode | default "embedded" -}}
{{- if eq $mode "shared_operator" -}}
shared_operator
{{- else -}}
embedded
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.databaseServerName" -}}
{{- if eq (include "poundcakeStackstorm.databaseMode" .) "shared_operator" -}}
{{- .Values.database.sharedOperator.serverName | default "" -}}
{{- else -}}
poundcake-mariadb
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.databaseServiceNamespace" -}}
{{- if eq (include "poundcakeStackstorm.databaseMode" .) "shared_operator" -}}
{{- .Values.database.sharedOperator.namespace | default .Release.Namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.databaseHost" -}}
{{- $mode := include "poundcakeStackstorm.databaseMode" . -}}
{{- $serverName := include "poundcakeStackstorm.databaseServerName" . -}}
{{- $namespace := include "poundcakeStackstorm.databaseServiceNamespace" . -}}
{{- if eq $mode "shared_operator" -}}
  {{- if and $serverName (ne $namespace .Release.Namespace) -}}
{{ printf "%s.%s.svc.cluster.local" $serverName $namespace }}
  {{- else -}}
{{ $serverName }}
  {{- end -}}
{{- else -}}
poundcake-mariadb
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.secretChecksumMaterial" -}}
{{- $material := dict
  "databaseMode" (include "poundcakeStackstorm.databaseMode" .)
  "databaseHost" (include "poundcakeStackstorm.databaseHost" .)
  "secrets" (.Values.secrets | default dict)
  "auth" (.Values.auth | default dict)
  "stackstorm" (.Values.stackstorm | default dict)
  "stackstormServices" (.Values.stackstormServices | default dict)
-}}
{{ toYaml $material }}
{{- end -}}

{{- define "poundcakeStackstorm.logGroupLabel" -}}
poundcake.io/log-group: "poundcake"
{{- end -}}

{{- define "poundcakeStackstorm.logRoleApi" -}}
poundcake.io/log-subgroup: "app"
poundcake.io/log-role: "api"
{{- end -}}

{{- define "poundcakeStackstorm.logRoleWorker" -}}
poundcake.io/log-subgroup: "app"
poundcake.io/log-role: "worker"
{{- end -}}

{{- define "poundcakeStackstorm.logRoleInfra" -}}
poundcake.io/log-subgroup: "data"
poundcake.io/log-role: "infra"
{{- end -}}

{{- define "poundcakeStackstorm.storageClass" -}}
{{- if .Values.persistence.storageClassName }}
storageClassName: {{ .Values.persistence.storageClassName | quote }}
{{- end }}
{{- end -}}

{{- define "poundcakeStackstorm.poundcakePullSecrets" -}}
{{- $pullSecrets := .Values.poundcakeImage.pullSecrets | default list -}}
{{- if gt (len $pullSecrets) 0 }}
imagePullSecrets:
{{- range $secret := $pullSecrets }}
  {{- if kindIs "string" $secret }}
  - name: {{ $secret | quote }}
  {{- else if and (kindIs "map" $secret) (hasKey $secret "name") }}
  - name: {{ index $secret "name" | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "poundcakeStackstorm.podPlacement" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "poundcakeStackstorm.poundcakeImageRef" -}}
{{- $digest := .Values.poundcakeImage.digest | default "" -}}
{{- if $digest -}}
{{- printf "%s@%s" .Values.poundcakeImage.repository $digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.poundcakeImage.repository (default .Chart.AppVersion .Values.poundcakeImage.tag) -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.poundcakeImageVersion" -}}
{{- $digest := .Values.poundcakeImage.digest | default "" -}}
{{- if $digest -}}
{{- $digest -}}
{{- else -}}
{{- default .Chart.AppVersion .Values.poundcakeImage.tag -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.pvcStorageClass" -}}
{{- $root := .root -}}
{{- $pvcStorageClass := .pvcStorageClass | default "" -}}
{{- if $pvcStorageClass }}
storageClassName: {{ $pvcStorageClass | quote }}
{{- else if $root.Values.persistence.storageClassName }}
storageClassName: {{ $root.Values.persistence.storageClassName | quote }}
{{- end }}
{{- end -}}

{{- define "poundcakeStackstorm.startupHookDeletePolicy" -}}
{{- $policies := list "before-hook-creation" -}}
{{- if and .Values.startupHooks.cleanup.enabled .Values.startupHooks.cleanup.deleteSuccessful -}}
{{- $policies = append $policies "hook-succeeded" -}}
{{- end -}}
{{- if and .Values.startupHooks.cleanup.enabled .Values.startupHooks.cleanup.deleteFailed -}}
{{- $policies = append $policies "hook-failed" -}}
{{- end -}}
{{- join "," $policies -}}
{{- end -}}

{{- define "poundcakeStackstorm.stackstormServiceEnabled" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- if not ($root.Values.stackstorm.enabled | default false) -}}
false
{{- else -}}
{{- $services := $root.Values.stackstormServices | default dict -}}
{{- $legacy := $root.Values.stackstormComponents | default dict -}}
{{- $defaults := dict
  "mongodb" true
  "rabbitmq" true
  "redis" true
  "auth" true
  "api" true
  "actionrunner" true
  "rulesengine" true
  "workflowengine" true
  "scheduler" true
  "notifier" false
  "garbagecollector" true
  "timersengine" false
  "sensorcontainer" false
  "register" false
  "stream" true
  "web" false
  "client" true
-}}
{{- if hasKey $services $name -}}
{{- $serviceCfg := index $services $name | default dict -}}
{{- ternary "true" "false" ($serviceCfg.enabled | default false) -}}
{{- else if hasKey $legacy $name -}}
{{- $legacyCfg := index $legacy $name | default dict -}}
{{- ternary "true" "false" ($legacyCfg.enabled | default false) -}}
{{- else -}}
{{- ternary "true" "false" (index $defaults $name | default false) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.validateStackstormServiceSet" -}}
{{- if .Values.stackstorm.enabled | default false -}}
{{- $required := list "mongodb" "rabbitmq" "redis" "auth" "api" "actionrunner" "rulesengine" "workflowengine" "scheduler" "garbagecollector" -}}
{{- $errors := list -}}
{{- range $svc := $required -}}
  {{- if ne (include "poundcakeStackstorm.stackstormServiceEnabled" (dict "root" $ "name" $svc)) "true" -}}
    {{- $errors = append $errors (printf "stackstormServices.%s.enabled must be true for Poundcake operations" $svc) -}}
  {{- end -}}
{{- end -}}
{{- if gt (len $errors) 0 -}}
{{- fail (printf "invalid stackstorm service profile: %s" (join "; " $errors)) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "poundcakeStackstorm.logLabels" -}}
{{- $group := .group | default "other" -}}
{{- $subgroup := .subgroup | default "general" -}}
{{- $role := .role | default "other" -}}
poundcake.io/log-group: {{ $group | quote }}
poundcake.io/log-subgroup: {{ $subgroup | quote }}
poundcake.io/log-role: {{ $role | quote }}
{{- end -}}

{{- define "poundcakeStackstorm.logLabelsForComponent" -}}
{{- $component := .component | default "unknown" -}}
{{- $group := "other" -}}
{{- $subgroup := "general" -}}
{{- $role := $component -}}

{{- if has $component (list "api" "ui" "prep-chef" "timer" "dishwasher") -}}
  {{- $group = "poundcake" -}}
  {{- $subgroup = "app" -}}
  {{- if eq $component "api" -}}
    {{- $role = "api" -}}
  {{- else if eq $component "ui" -}}
    {{- $role = "ui" -}}
  {{- else -}}
    {{- $role = "worker" -}}
  {{- end -}}
{{- else if has $component (list "mariadb" "stackstorm-mongodb" "stackstorm-rabbitmq" "stackstorm-redis") -}}
  {{- $group = "infra" -}}
  {{- $subgroup = "data" -}}
  {{- if hasPrefix "stackstorm-" $component -}}
    {{- $role = trimPrefix "stackstorm-" $component -}}
  {{- end -}}
{{- else if hasPrefix "stackstorm-" $component -}}
  {{- $role = trimPrefix "stackstorm-" $component -}}
  {{- if has $component (list "stackstorm-auth" "stackstorm-api" "stackstorm-stream" "stackstorm-web") -}}
    {{- $group = "stackstorm-edge" -}}
    {{- $subgroup = "control-api" -}}
  {{- else if has $component (list "stackstorm-actionrunner" "stackstorm-rulesengine" "stackstorm-workflowengine" "stackstorm-scheduler" "stackstorm-register" "stackstorm-garbagecollector" "stackstorm-client" "stackstorm-notifier" "stackstorm-timersengine" "stackstorm-sensorcontainer") -}}
    {{- $group = "stackstorm-exec" -}}
    {{- $subgroup = "control-exec" -}}
  {{- else if has $component (list "stackstorm-startup-markers-reset" "stackstorm-mongodb-user-sync" "stackstorm-infra-ready" "stackstorm-controlplane-ready" "stackstorm-workers-ready" "stackstorm-edge-ready" "stackstorm-bootstrap") -}}
    {{- $group = "startup-hooks" -}}
    {{- $subgroup = "orchestration" -}}
    {{- $role = $component -}}
  {{- end -}}
{{- else if hasPrefix "poundcake-" $component -}}
  {{- $group = "startup-hooks" -}}
  {{- $subgroup = "orchestration" -}}
{{- end -}}

{{- include "poundcakeStackstorm.logLabels" (dict "group" $group "subgroup" $subgroup "role" $role) -}}
{{- end -}}

{{- define "poundcakeStackstorm.gateLogHelpers" -}}
GATE_LOG_ENABLED="{{ ternary "true" "false" .Values.startupHooks.gateLogging.enabled }}"
GATE_LOG_INTERVAL="{{ .Values.startupHooks.gateLogging.intervalSeconds }}"
GATE_LOG_PREFIX={{ .Values.startupHooks.gateLogging.prefix | quote }}
case "${GATE_LOG_INTERVAL}" in
  ''|*[!0-9]*) GATE_LOG_INTERVAL=30 ;;
esac
if [ "${GATE_LOG_INTERVAL}" -lt 1 ]; then
  GATE_LOG_INTERVAL=1
fi

gate_log_wait_start() {
  gate_name="$1"
  gate_detail="$2"
  gate_started_at="$(date +%s)"
  gate_last_log="${gate_started_at}"
  echo "${GATE_LOG_PREFIX} wait=${gate_name} status=waiting elapsed=0s detail=${gate_detail}"
}

gate_log_wait_tick() {
  gate_name="$1"
  gate_detail="$2"
  gate_now="$(date +%s)"
  if [ "${GATE_LOG_ENABLED}" = "true" ] && [ $((gate_now - gate_last_log)) -ge "${GATE_LOG_INTERVAL}" ]; then
    echo "${GATE_LOG_PREFIX} wait=${gate_name} status=waiting elapsed=$((gate_now - gate_started_at))s detail=${gate_detail}"
    gate_last_log="${gate_now}"
  fi
}

gate_log_wait_ready() {
  gate_name="$1"
  gate_now="$(date +%s)"
  echo "${GATE_LOG_PREFIX} wait=${gate_name} status=ready elapsed=$((gate_now - gate_started_at))s"
}

gate_wait_for_true_file() {
  gate_file="$1"
  gate_name="$2"
  gate_detail="$3"
  gate_log_wait_start "${gate_name}" "${gate_detail}"
  until [ "$(cat "${gate_file}" 2>/dev/null)" = "true" ]; do
    gate_log_wait_tick "${gate_name}" "${gate_detail}"
    sleep 2
  done
  gate_log_wait_ready "${gate_name}"
}

gate_wait_for_nonempty_file() {
  gate_file="$1"
  gate_name="$2"
  gate_detail="$3"
  gate_log_wait_start "${gate_name}" "${gate_detail}"
  until [ -n "$(cat "${gate_file}" 2>/dev/null)" ]; do
    gate_log_wait_tick "${gate_name}" "${gate_detail}"
    sleep 2
  done
  gate_log_wait_ready "${gate_name}"
}

gate_wait_for_tcp() {
  gate_host="$1"
  gate_port="$2"
  gate_name="$3"
  gate_detail="$4"
  gate_log_wait_start "${gate_name}" "${gate_detail}"
  until nc -z "${gate_host}" "${gate_port}"; do
    gate_log_wait_tick "${gate_name}" "${gate_detail}"
    sleep 2
  done
  gate_log_wait_ready "${gate_name}"
}

gate_wait_for_http_status() {
  gate_url="$1"
  gate_name="$2"
  gate_detail="$3"
  shift 3
  gate_log_wait_start "${gate_name}" "${gate_detail}"
  while true; do
    gate_resp="$(wget -S -O /dev/null "${gate_url}" 2>&1 || true)"
    for gate_code in "$@"; do
      case "${gate_resp}" in
        *" ${gate_code} "*)
          gate_log_wait_ready "${gate_name}"
          return 0
          ;;
      esac
    done
    gate_log_wait_tick "${gate_name}" "${gate_detail}"
    sleep 2
  done
}
{{- end -}}
