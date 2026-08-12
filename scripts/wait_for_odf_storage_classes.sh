#!/bin/bash

set -e

kubectl wait storagecluster ocs-storagecluster \
  -n openshift-storage \
  --for=jsonpath='{.status.phase}'=Ready \
  --timeout=30m
