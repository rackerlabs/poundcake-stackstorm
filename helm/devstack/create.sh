#!/usr/bin/env bash
# Create a local kind cluster and optionally install the PoundCake StackStorm Helm chart.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CHART_DIR="${CHART_DIR:-$PROJECT_ROOT/helm}"
KIND_CONFIG="${KIND_CONFIG:-$SCRIPT_DIR/kind-config.yaml}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-poundcake-stackstorm}"
KIND_NODE_IMAGE="${KIND_NODE_IMAGE:-}"
NAMESPACE="${NAMESPACE:-poundcake-stackstorm}"
RELEASE_NAME="${RELEASE_NAME:-poundcake-stackstorm}"
INSTALL_CHART="${INSTALL_CHART:-true}"
WAIT="${WAIT:-true}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-15m}"
VALUES_FILE="${VALUES_FILE:-$SCRIPT_DIR/values/stackstorm-kind.yaml}"
HELM_EXTRA_ARGS="${HELM_EXTRA_ARGS:-}"

log() {
    printf '[helm-devstack-create] %s\n' "$*"
}

fail() {
    printf '[helm-devstack-create] ERROR: %s\n' "$*" >&2
    exit 1
}

detect_executable() {
    local env_var="$1"
    local command_name="$2"
    shift 2
    local configured="${!env_var:-}"
    local candidate

    if [ -n "$configured" ]; then
        [ -x "$configured" ] || fail "$env_var is set but not executable: $configured"
        printf '%s\n' "$configured"
        return 0
    fi

    if command -v "$command_name" >/dev/null 2>&1; then
        command -v "$command_name"
        return 0
    fi

    for candidate in "$@"; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    fail "$command_name is not installed or not in PATH"
}

KIND_BIN="$(detect_executable KIND_BIN kind /opt/homebrew/bin/kind /usr/local/bin/kind)"
KUBECTL_BIN="$(detect_executable KUBECTL_BIN kubectl /opt/homebrew/bin/kubectl /usr/local/bin/kubectl)"
HELM_BIN="$(detect_executable HELM_BIN helm /opt/homebrew/bin/helm /usr/local/bin/helm)"

if "$KIND_BIN" get clusters | grep -Fxq "$KIND_CLUSTER_NAME"; then
    log "kind cluster already exists: $KIND_CLUSTER_NAME"
else
    create_args=(create cluster --name "$KIND_CLUSTER_NAME" --config "$KIND_CONFIG")
    if [ -n "$KIND_NODE_IMAGE" ]; then
        create_args+=(--image "$KIND_NODE_IMAGE")
    fi
    log "creating kind cluster $KIND_CLUSTER_NAME from $KIND_CONFIG"
    "$KIND_BIN" "${create_args[@]}"
fi

"$KUBECTL_BIN" config use-context "kind-$KIND_CLUSTER_NAME" >/dev/null
log "using kubectl context kind-$KIND_CLUSTER_NAME"

if [ "$INSTALL_CHART" != "true" ]; then
    log "INSTALL_CHART=false; cluster is ready without Helm install"
    exit 0
fi

"$KUBECTL_BIN" create namespace "$NAMESPACE" --dry-run=client -o yaml | "$KUBECTL_BIN" apply -f -

helm_args=(
    upgrade
    --install
    "$RELEASE_NAME"
    "$CHART_DIR"
    --namespace
    "$NAMESPACE"
)
if [ "$WAIT" = "true" ]; then
    helm_args+=(--wait --timeout "$WAIT_TIMEOUT")
fi
if [ -n "$VALUES_FILE" ]; then
    [ -f "$VALUES_FILE" ] || fail "VALUES_FILE does not exist: $VALUES_FILE"
    helm_args+=(-f "$VALUES_FILE")
fi
if [ -n "$HELM_EXTRA_ARGS" ]; then
    read -r -a extra_args <<< "$HELM_EXTRA_ARGS"
    helm_args+=("${extra_args[@]}")
fi

log "installing Helm release $RELEASE_NAME in namespace $NAMESPACE"
"$HELM_BIN" "${helm_args[@]}"

log "Helm devstack is ready"
log "cluster: kind-$KIND_CLUSTER_NAME"
log "namespace: $NAMESPACE"
log "release: $RELEASE_NAME"
