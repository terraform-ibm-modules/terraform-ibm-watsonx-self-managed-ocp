#!/bin/bash
# filepath: ./scripts/wait_for_cpd_pod.sh

set -e
NAMESPACE="cloud-pak-deployer"
POD_NAME=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
STATUS=""
while true; do
  STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
  echo "Pod status: $STATUS"
  if [[ "$STATUS" == "Succeeded" || "$STATUS" == "Failed" ]]; then
    break
  fi
  sleep 300
done
