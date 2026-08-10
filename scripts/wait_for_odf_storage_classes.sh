#!/bin/bash
# filepath: ./scripts/wait_for_odf_storage_classes.sh

set -e

kubectl wait storagecluster ocs-storagecluster \
  -n openshift-storage \
  --for=jsonpath='{.status.phase}'=Ready \
  --timeout=30m
