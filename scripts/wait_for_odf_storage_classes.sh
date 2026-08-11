#!/bin/bash

set -e

NAMESPACE="openshift-storage"
STORAGE_CLUSTER="ocs-storagecluster"
TIMEOUT="30m"

echo "INFO: Waiting for ODF StorageCluster '${STORAGE_CLUSTER}' to reach Ready phase (timeout: ${TIMEOUT})..."

if kubectl wait storagecluster "${STORAGE_CLUSTER}" \
  -n "${NAMESPACE}" \
  --for=jsonpath='{.status.phase}'=Ready \
  --timeout="${TIMEOUT}"; then

  echo "INFO: ODF StorageCluster is Ready."

else
  echo "ERROR: ODF StorageCluster did not reach Ready within ${TIMEOUT}."

  echo "INFO: StorageCluster status:"
  kubectl get storagecluster "${STORAGE_CLUSTER}" \
    -n "${NAMESPACE}" \
    -o jsonpath='{.status}' | python3 -m json.tool 2>/dev/null || \
  kubectl get storagecluster "${STORAGE_CLUSTER}" -n "${NAMESPACE}"

  echo "INFO: StorageCluster description:"
  kubectl describe storagecluster "${STORAGE_CLUSTER}" -n "${NAMESPACE}" || true

  echo "INFO: ODF pods:"
  kubectl get pods -n "${NAMESPACE}" -o wide || true

  echo "INFO: ODF events:"
  kubectl get events \
    -n "${NAMESPACE}" \
    --sort-by=.lastTimestamp || true

  exit 1
fi
