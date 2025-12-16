#!/bin/bash
# filepath: ./scripts/wait_for_cpd_pod.sh

set -e
NAMESPACE="cloud-pak-deployer"
POD_NAME=$(kubectl get pods --sort-by=.metadata.creationTimestamp -n "${NAMESPACE}" -o jsonpath='{.items[-1].metadata.name}')
STATUS=""
while true; do
  kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}'
  STATUS=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')
  echo "Pod status: ${STATUS}"
  if [[ "${STATUS}" == "Succeeded" ]]; then
    break
  elif [[ "${STATUS}" == "Failed" ]]; then
    echo "Exiting due to 'Failed' status. Check pod logs for more info."
    exit 1
  fi
  sleep 60
done
