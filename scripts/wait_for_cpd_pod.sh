#!/bin/bash
# filepath: ./scripts/wait_for_cpd_pod.sh

set -e
NAMESPACE="cloud-pak-deployer"
POD_NAME=$(kubectl get pods --sort-by=.metadata.creationTimestamp -n "${NAMESPACE}" -o jsonpath='{.items[-1].metadata.name}')
STATUS=""

dump_debug_info() {
  echo "Collecting diagnostics for pod ${POD_NAME} in namespace ${NAMESPACE}..."
  echo
  echo "Pods:"
  kubectl get pods -n "${NAMESPACE}" -o wide || true
  echo
  echo "Pod description:"
  kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}" || true
  echo
  echo "Pod logs:"
  kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --all-containers=true || true
  echo
  echo "Namespace events:"
  kubectl get events -n "${NAMESPACE}" --sort-by=.lastTimestamp || true
}

while true; do
  STATUS=$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}')
  echo "Pod status: ${STATUS}"
  if [[ "${STATUS}" == "Succeeded" ]]; then
    break
  elif [[ "${STATUS}" == "Failed" ]]; then
    echo "Exiting due to 'Failed' status. Check pod logs for more info."
    dump_debug_info
    exit 1
  fi
  sleep 60
done
