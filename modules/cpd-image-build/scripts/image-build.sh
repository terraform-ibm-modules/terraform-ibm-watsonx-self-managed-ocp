#!/bin/bash

BUILD_OUTPUT=$(curl -X POST "https://api.${REGION}.codeengine.cloud.ibm.com/v2/projects/${PROJECT_ID}/build_runs" -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" -d '{ "build_name": "cpd-build" }')
RC=$?

BUILD_NAME=$(echo "${BUILD_OUTPUT}" | jq -r .name)

if [ $RC -ne 0 ] || [ "${BUILD_NAME}" == "null" ]; then
  echo "Creation of build run failed with rc = ${RC}.  Output = ${BUILD_OUTPUT}"
  exit 1;
fi

SLEEP_SECONDS=60
NUMBER_OF_RETRIES=15
COMPLETE=false

i=0
while [ "${i}" -lt "${NUMBER_OF_RETRIES}" ]; do

  echo "Running job ... $i"

  BUILD_RUN_OUTPUT=$(curl -X GET "https://api.${REGION}.codeengine.cloud.ibm.com/v2/projects/${PROJECT_ID}/build_runs/${BUILD_NAME}" -H "Authorization: ${TOKEN}")
  echo "${BUILD_RUN_OUTPUT}"

  BUILD_STATUS=$(echo "${BUILD_RUN_OUTPUT}" | jq -r .status)
  if [ "${BUILD_STATUS}" == "succeeded" ]; then COMPLETE=true && break; fi

  i=$((i+1))

  sleep "${SLEEP_SECONDS}"
done

if [ "${COMPLETE}" = false ]; then
  echo "The build run did not complete in the allotted time.  Output = ${BUILD_RUN_OUTPUT}"
  exit 1;
fi

exit 0;
