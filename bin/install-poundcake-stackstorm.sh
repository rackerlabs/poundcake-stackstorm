#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NAMESPACE="${POUNDCAKE_STACKSTORM_NAMESPACE:-poundcake}"
RELEASE_NAME="${POUNDCAKE_STACKSTORM_RELEASE_NAME:-poundcake-stackstorm}"
CHART_REF="${POUNDCAKE_STACKSTORM_CHART_REF:-${REPO_ROOT}/helm}"
VALUES_FILE="${POUNDCAKE_STACKSTORM_VALUES_FILE:-}"
OVERRIDES_DIR="${POUNDCAKE_STACKSTORM_OVERRIDES_DIR:-/etc/genestack/helm-configs/poundcake-stackstorm}"
HELM_WAIT="${POUNDCAKE_STACKSTORM_HELM_WAIT:-true}"
HELM_TIMEOUT="${POUNDCAKE_STACKSTORM_HELM_TIMEOUT:-30m}"

args=(upgrade --install "${RELEASE_NAME}" "${CHART_REF}" --namespace "${NAMESPACE}" --create-namespace)
if [[ "${HELM_WAIT}" == "true" ]]; then
  args+=(--wait --timeout "${HELM_TIMEOUT}")
fi
if [[ -n "${VALUES_FILE}" ]]; then
  args+=(-f "${VALUES_FILE}")
fi
if [[ -d "${OVERRIDES_DIR}" ]]; then
  while IFS= read -r file; do
    args+=(-f "${file}")
  done < <(find "${OVERRIDES_DIR}" -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)
fi
args+=("$@")

helm "${args[@]}"
