#!/bin/bash

set -e

# Wait for the ODF operator to install the storagecluster CRD before running kubectl wait.
# The ODF addon creation completes before the operator finishes deploying CRDs.
CRD_TIMEOUT=1800  # 30 minutes
CRD_INTERVAL=30
elapsed=0

echo "Waiting for storagecluster CRD to be available..."
until kubectl get crd storageclusters.ocs.openshift.io &>/dev/null; do
  if [ "$elapsed" -ge "$CRD_TIMEOUT" ]; then
    echo "Timed out waiting for storagecluster CRD after ${CRD_TIMEOUT}s"
    exit 1
  fi
  echo "storagecluster CRD not yet available, retrying in ${CRD_INTERVAL}s (${elapsed}s elapsed)..."
  sleep "$CRD_INTERVAL"
  elapsed=$((elapsed + CRD_INTERVAL))
done

echo "storagecluster CRD is available. Waiting for StorageCluster to be Ready..."
kubectl wait storagecluster ocs-storagecluster \
  -n openshift-storage \
  --for=jsonpath='{.status.phase}'=Ready \
  --timeout=30m
