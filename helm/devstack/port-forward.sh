#!/usr/bin/env bash
# Manage local port-forwards to StackStorm services in the kind devstack.

set -euo pipefail

ACTION="${1:-start}"
NAMESPACE="${NAMESPACE:-poundcake-stackstorm}"
TMP_DIR="${TMP_DIR:-/tmp/poundcake-stackstorm-helm-devstack}"
KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"

log() {
    printf '[helm-devstack-port-forward] %s\n' "$*"
}

service_spec() {
    case "$1" in
        api)
            printf 'svc/stackstorm-api 9101:9101\n'
            ;;
        auth)
            printf 'svc/stackstorm-auth 9100:9100\n'
            ;;
        stream)
            printf 'svc/stackstorm-stream 9102:9102\n'
            ;;
        web)
            printf 'svc/stackstorm-web 8080:8080\n'
            ;;
        *)
            printf 'unknown service: %s\n' "$1" >&2
            exit 2
            ;;
    esac
}

pid_file() {
    printf '%s/%s.pid\n' "$TMP_DIR" "$1"
}

log_file() {
    printf '%s/%s.log\n' "$TMP_DIR" "$1"
}

is_running() {
    local pid="$1"
    [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

start_one() {
    local name="$1"
    local spec
    local target
    local ports
    local pid_path
    local existing_pid

    spec="$(service_spec "$name")"
    target="${spec%% *}"
    ports="${spec#* }"

    mkdir -p "$TMP_DIR"
    pid_path="$(pid_file "$name")"
    existing_pid="$([ -f "$pid_path" ] && cat "$pid_path" || true)"
    if is_running "$existing_pid"; then
        log "$name already running with pid $existing_pid"
        return 0
    fi

    log "starting $name port-forward: 127.0.0.1:${ports%%:*} -> $target"
    "$KUBECTL_BIN" -n "$NAMESPACE" port-forward "$target" "$ports" >"$(log_file "$name")" 2>&1 &
    printf '%s\n' "$!" > "$pid_path"
}

stop_one() {
    local name="$1"
    local pid_path
    local existing_pid

    pid_path="$(pid_file "$name")"
    existing_pid="$([ -f "$pid_path" ] && cat "$pid_path" || true)"
    if is_running "$existing_pid"; then
        log "stopping $name port-forward pid $existing_pid"
        kill "$existing_pid"
    fi
    rm -f "$pid_path"
}

status_one() {
    local name="$1"
    local pid_path
    local existing_pid

    pid_path="$(pid_file "$name")"
    existing_pid="$([ -f "$pid_path" ] && cat "$pid_path" || true)"
    if is_running "$existing_pid"; then
        log "$name running with pid $existing_pid"
    else
        log "$name stopped"
    fi
}

case "$ACTION" in
    start)
        for name in api auth stream web; do
            start_one "$name"
        done
        log "StackStorm API: http://127.0.0.1:9101"
        log "StackStorm Auth: http://127.0.0.1:9100"
        log "StackStorm Stream: http://127.0.0.1:9102"
        log "StackStorm Web: http://127.0.0.1:8080"
        ;;
    stop)
        for name in api auth stream web; do
            stop_one "$name"
        done
        ;;
    restart)
        "$0" stop
        "$0" start
        ;;
    status)
        for name in api auth stream web; do
            status_one "$name"
        done
        ;;
    *)
        printf 'usage: %s {start|stop|restart|status}\n' "$0" >&2
        exit 2
        ;;
esac
