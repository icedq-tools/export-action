#!/usr/bin/env bash
set -euo pipefail

ARGS=(
  "export"
  "--resource" "${RESOURCE}"
  "--id" "${RESOURCE_ID}"
  "--output" "${OUTPUT_FILE}"
  "--timeout" "${TIMEOUT}"
  "--output-format" "json"
)

if [[ "${INCLUDE_CHILD:-false}" == "true" ]]; then
  ARGS+=("--include-child")
fi

# Ensure parent directory for the output file exists.
mkdir -p "$(dirname "${OUTPUT_FILE}")"

TMP_JSON="$(mktemp)"
TMP_ERR="$(mktemp)"
set +e
icedq "${ARGS[@]}" >"${TMP_JSON}" 2>"${TMP_ERR}"
EXIT_CODE=$?
set -e

# Forward CLI stderr (logs + task-id banner) to the action log.
cat "${TMP_ERR}" >&2

TASK_ID="$(grep -oE 'task-id:[[:space:]]*[^[:space:]]+' "${TMP_ERR}" | head -1 | awk '{print $2}' || true)"
if command -v jq >/dev/null 2>&1; then
  STATUS="$(jq -r '.status // empty' "${TMP_JSON}" 2>/dev/null || true)"
  BUNDLE_PATH="$(jq -r '.outputFile // empty' "${TMP_JSON}" 2>/dev/null || true)"
else
  STATUS="$(node -e "try{console.log(JSON.parse(require('fs').readFileSync('${TMP_JSON}','utf8')).status||'')}catch(e){}")"
  BUNDLE_PATH="$(node -e "try{console.log(JSON.parse(require('fs').readFileSync('${TMP_JSON}','utf8')).outputFile||'')}catch(e){}")"
fi

# Fall back to the requested OUTPUT_FILE when CLI didn't surface it (e.g. on failure).
if [[ -z "${BUNDLE_PATH}" ]]; then
  BUNDLE_PATH="${OUTPUT_FILE}"
fi

{
  echo "task-id=${TASK_ID:-}"
  echo "status=${STATUS:-Unknown}"
  echo "bundle-path=${BUNDLE_PATH}"
} >>"${GITHUB_OUTPUT}"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## iceDQ export"
    echo ""
    echo "- **Status:** ${STATUS:-Unknown}"
    echo "- **Task ID:** \`${TASK_ID:-n/a}\`"
    echo "- **Resource:** \`${RESOURCE}\` (\`${RESOURCE_ID}\`)"
    echo "- **Workspace:** \`${ICEDQ_WORKSPACE_ID}\`"
    echo "- **Bundle:** \`${BUNDLE_PATH}\`"
  } >>"${GITHUB_STEP_SUMMARY}"
fi

cat "${TMP_JSON}"

exit "${EXIT_CODE}"
