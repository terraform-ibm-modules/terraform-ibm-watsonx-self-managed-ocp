#!/bin/bash

${OC} create -f "${JOB_UNINSTALL_CPD_FILENAME}"
RC=$?
if [ "${RC}" -ne 0 ]; then echo "Unable to create job ${JOB_NAME}; exiting..." && exit 1; fi

timeout_seconds=1800 # 30 minutes
sleep_seconds=5
number_of_tries=$((timeout_seconds / sleep_seconds))
complete=false
failed=false

i=0
while [ $i -lt "${number_of_tries}" ]; do

echo "Running job ... $i"
${OC} get jobs -n "${NAMESPACE_NAME}"

${OC} wait --for=condition=complete job "${JOB_NAME}" -n "${NAMESPACE_NAME}" --timeout=0 2>/dev/null
RC=$?
if [ "${RC}" -eq 0 ]; then complete=true && break; fi

${OC} wait --for=condition=failed job "${JOB_NAME}" -n "${NAMESPACE_NAME}" --timeout=0 2>/dev/null
RC=$?
if [ "${RC}" -eq 0 ]; then failed=true && break; fi

i=$((i+1))

sleep "${sleep_seconds}"

done

${OC} describe pods -n "${NAMESPACE_NAME}"

if $failed; then
    echo "Job ${JOB_NAME} failed"
    exit 1
elif "${complete}"; then
    echo "Job ${JOB_NAME} completed successfully"
    ${OC} delete -f "${JOB_UNINSTALL_CPD_FILENAME}"
    RC=$?
    if [ "${RC}" -ne 0 ]; then echo "Unable to delete job ${JOB_NAME}; exiting..." && exit 1; fi
    exit 0
fi
