#!/bin/bash

set -o pipefail

echo "==> Starting Code Engine build run for build 'cpd-build' in project ${PROJECT_ID} (region: ${REGION})"

BUILD_OUTPUT=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "https://api.${REGION}.codeengine.cloud.ibm.com/v2/projects/${PROJECT_ID}/build_runs" \
  -H "Authorization: ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{ "build_name": "cpd-build" }')
RC=$?

HTTP_STATUS=$(echo "${BUILD_OUTPUT}" | grep "HTTP_STATUS:" | cut -d: -f2)
BUILD_OUTPUT=$(echo "${BUILD_OUTPUT}" | grep -v "HTTP_STATUS:")
BUILD_NAME=$(echo "${BUILD_OUTPUT}" | jq -r .name)

echo "==> POST build_runs HTTP status: ${HTTP_STATUS}"

if [ $RC -ne 0 ] || [ "${BUILD_NAME}" == "null" ]; then
  echo "ERROR: Failed to create build run (curl rc=${RC}, http=${HTTP_STATUS})"
  echo "       Response: ${BUILD_OUTPUT}"
  exit 1
fi

echo "==> Build run created: ${BUILD_NAME}"

SLEEP_SECONDS=60
NUMBER_OF_RETRIES=15
COMPLETE=false

i=0
while [ "${i}" -lt "${NUMBER_OF_RETRIES}" ]; do

  echo "==> Polling build run status (attempt $((i+1))/${NUMBER_OF_RETRIES}) ..."

  BUILD_RUN_OUTPUT=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X GET "https://api.${REGION}.codeengine.cloud.ibm.com/v2/projects/${PROJECT_ID}/build_runs/${BUILD_NAME}" \
    -H "Authorization: ${TOKEN}")

  POLL_HTTP=$(echo "${BUILD_RUN_OUTPUT}" | grep "HTTP_STATUS:" | cut -d: -f2)
  BUILD_RUN_OUTPUT=$(echo "${BUILD_RUN_OUTPUT}" | grep -v "HTTP_STATUS:")

  BUILD_STATUS=$(echo "${BUILD_RUN_OUTPUT}"    | jq -r .status)
  BUILD_REASON=$(echo "${BUILD_RUN_OUTPUT}"    | jq -r '.status_details.reason // "none"')
  BUILD_START=$(echo "${BUILD_RUN_OUTPUT}"     | jq -r '.status_details.start_time // "unknown"')
  BUILD_COMPLETE=$(echo "${BUILD_RUN_OUTPUT}"  | jq -r '.status_details.completion_time // "in-progress"')

  echo "    status=${BUILD_STATUS}  reason=${BUILD_REASON}  started=${BUILD_START}  completed=${BUILD_COMPLETE}  http=${POLL_HTTP}"

  if [ "${BUILD_STATUS}" == "succeeded" ]; then
    echo "==> Build run succeeded."
    COMPLETE=true
    break
  fi

  if [ "${BUILD_STATUS}" == "failed" ]; then
    echo "ERROR: Build run failed."
    echo "       reason          : ${BUILD_REASON}"
    echo "       start_time      : ${BUILD_START}"
    echo "       completion_time : ${BUILD_COMPLETE}"
    echo "       git_commit_sha  : $(echo "${BUILD_RUN_OUTPUT}" | jq -r '.status_details.git_commit_sha // "unknown"')"
    echo "       git_author      : $(echo "${BUILD_RUN_OUTPUT}" | jq -r '.status_details.git_commit_author // "unknown"')"
    echo "       full response   : ${BUILD_RUN_OUTPUT}"
    exit 1
  fi

  i=$((i+1))
  sleep "${SLEEP_SECONDS}"
done

if [ "${COMPLETE}" = false ]; then
  echo "ERROR: Build run did not complete within $((NUMBER_OF_RETRIES * SLEEP_SECONDS))s."
  echo "       Last status : ${BUILD_STATUS}"
  echo "       Last reason : ${BUILD_REASON}"
  echo "       Full response: ${BUILD_RUN_OUTPUT}"
  exit 1
fi

exit 0
