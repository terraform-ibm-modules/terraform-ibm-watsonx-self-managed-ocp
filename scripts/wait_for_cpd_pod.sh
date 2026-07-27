#!/bin/bash
# filepath: ./scripts/wait_for_cpd_pod.sh

set -e
NAMESPACE="cloud-pak-deployer"
POD_NAME=$(kubectl get pods --sort-by=.metadata.creationTimestamp -n "${NAMESPACE}" -o jsonpath='{.items[-1].metadata.name}')
STATUS=""
while true; do
  STATUS=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')
  echo "Pod status: ${STATUS}"
  if [[ "${STATUS}" == "Succeeded" ]]; then
    break
  elif [[ "${STATUS}" == "Failed" ]]; then
    echo "Pod failed. Collecting diagnostics before exit..."
    echo "=== kubectl get pods -n ${NAMESPACE} -o wide ==="
    kubectl get pods -n "${NAMESPACE}" -o wide || true
    echo "=== kubectl describe pod ${POD_NAME} -n ${NAMESPACE} ==="
    kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}" || true
    echo "=== kubectl logs ${POD_NAME} -n ${NAMESPACE} --all-containers=true ==="
    kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --all-containers=true || true
    echo "=== kubectl get events -n ${NAMESPACE} --sort-by=.lastTimestamp ==="
    kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp || true
    echo "Exiting due to 'Failed' status after collecting diagnostics."
    exit 1
  fi
  sleep 60
done
