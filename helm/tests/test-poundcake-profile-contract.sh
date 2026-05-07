#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROFILE_FILE="${PROJECT_ROOT}/packs/poundcake/poundcake_profiles.json"
HELM_PROFILE_FILE="${PROJECT_ROOT}/helm/files/packs/poundcake/poundcake_profiles.json"
ACTION_DIR="${PROJECT_ROOT}/packs/poundcake/actions"
WORKFLOW_DIR="${ACTION_DIR}/workflows"

fail() {
    printf '[FAIL] %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}

require_cmd jq
require_cmd cmp

cmp -s "${PROFILE_FILE}" "${HELM_PROFILE_FILE}" \
    || fail "pack profile contract differs between packs/ and helm/files/packs/"

jq -e '.version == 1 and (.profiles | type == "array") and (.profiles | length > 0)' \
    "${PROFILE_FILE}" >/dev/null \
    || fail "profile contract must define version 1 and at least one profile"

jq -e '
  all(.profiles[];
    (.noop_severities | index("warning")) != null
    and ((.actionable_severities | index("warning")) == null)
  )
' "${PROFILE_FILE}" >/dev/null \
    || fail "every profile must mark warning as noop and exclude warning from actionable severities"

jq -r '
      def slug: gsub("-"; "_");
      .profiles[] as $profile
      | if $profile.workflow_refs then
          $profile.workflow_refs[]
        elif $profile.domain == "etcd" then
          $profile.alert_groups[] as $group
          | $profile.workflow_phases[] as $phase
          | "\($profile.workflow_prefix)\($group | slug)_\($phase)"
        else
          $profile.alert_groups[]
          | "\($profile.workflow_prefix)\(. | slug)\($profile.workflow_suffix)"
        end
' "${PROFILE_FILE}" | sort -u > /tmp/poundcake-stackstorm-profile-workflows.txt

[ -s /tmp/poundcake-stackstorm-profile-workflows.txt ] \
    || fail "profile contract did not define workflow refs"

while IFS= read -r workflow_ref; do
    action_name="${workflow_ref#poundcake.}"
    action_file="${ACTION_DIR}/${action_name}.yaml"
    workflow_file="${WORKFLOW_DIR}/${action_name}.yaml"
    [ -f "${action_file}" ] || fail "missing action metadata for ${workflow_ref}"
    [ -f "${workflow_file}" ] || fail "missing workflow file for ${workflow_ref}"
    grep -q "^name: ${action_name}$" "${action_file}" \
        || fail "action metadata name mismatch for ${workflow_ref}"
    grep -q "^entry_point: workflows/${action_name}.yaml$" "${action_file}" \
        || fail "action metadata entry_point mismatch for ${workflow_ref}"
done < /tmp/poundcake-stackstorm-profile-workflows.txt

printf '[PASS] PoundCake StackStorm profile contract checks passed\n'
