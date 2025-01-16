#!/bin/bash

# Create manifest for uninstall
UNINSTALL_MANIFEST="/tmp/uninstall.yml"
cat > "${UNINSTALL_MANIFEST}" << EOF
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app: ${CLOUD_PAK_DEPLOYER_JOB_LABEL}-uninstall-cpd
  name: ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}
  namespace: ${CLOUD_PAK_DEPLOYER_NAMESPACE_NAME}
spec:
  parallelism: 1
  completions: 1
  backoffLimit: 0
  template:
    metadata:
      name: ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}
      labels:
        app: ${CLOUD_PAK_DEPLOYER_JOB_LABEL}-uninstall-cpd
    spec:
      imagePullSecrets:
        ${CLOUD_PAK_DEPLOYER_IMAGE_SECRET}
      containers:
        - name: ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}
          image: ${CLOUD_PAK_DEPLOYER_IMAGE}
          imagePullPolicy: Always
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          env:
            - name: CONFIG_DIR
              value: /Data/cpd-config
            - name: STATUS_DIR
              value: /Data/cpd-status
          volumeMounts:
            - name: config-volume
              mountPath: /Data/cpd-config/config
            - name: status-volume
              mountPath: /Data/cpd-status
          command: ["/bin/sh", "-xc"]
          args:
            - /cloud-pak-deployer/scripts/cp4d/cp4d-delete-instance.sh cpd <<< "y"
      restartPolicy: Never
      securityContext:
        runAsUser: 0
      serviceAccountName: ${CLOUD_PAK_DEPLOYER_SERVICE_ACCOUNT_NAME}
      volumes:
        - name: config-volume
          configMap:
            name: ${CLOUD_PAK_DEPLOYER_CONFIG_MAP_NAME}
        - name: status-volume
          persistentVolumeClaim:
            claimName: ${CLOUD_PAK_DEPLOYER_PERSISTENT_VOLUME_CLAIM_NAME}
EOF

${OC} create -f "${UNINSTALL_MANIFEST}"
RC=$?
if [ "${RC}" -ne 0 ]; then echo "Unable to create job ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}; exiting..." && exit 1; fi

timeout_seconds=1800 # 30 minutes
sleep_seconds=5
number_of_tries=$((timeout_seconds / sleep_seconds))
complete=false
failed=false

i=0
while [ $i -lt "${number_of_tries}" ]; do

  echo "Running job ... $i"
  ${OC} get jobs -n "${CLOUD_PAK_DEPLOYER_NAMESPACE_NAME}"

  ${OC} wait --for=condition=complete job "${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}" -n "${CLOUD_PAK_DEPLOYER_NAMESPACE_NAME}" --timeout=0 2>/dev/null
  RC=$?
  if [ "${RC}" -eq 0 ]; then complete=true && break; fi

  ${OC} wait --for=condition=failed job "${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}" -n "${CLOUD_PAK_DEPLOYER_NAMESPACE_NAME}" --timeout=0 2>/dev/null
  RC=$?
  if [ "${RC}" -eq 0 ]; then failed=true && break; fi

  i=$((i+1))

  sleep "${sleep_seconds}"

done

${OC} describe pods -n "${CLOUD_PAK_DEPLOYER_NAMESPACE_NAME}"

if $failed; then
    echo "Job ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME} failed"
    exit 1
elif "${complete}"; then
    echo "Job ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME} completed successfully"
    ${OC} delete -f "${UNINSTALL_MANIFEST}"
    RC=$?
    if [ "${RC}" -ne 0 ]; then echo "Unable to delete job ${CLOUD_PAK_DEPLOYER_UNINSTALL_JOB_NAME}; exiting..." && exit 1; fi
    exit 0
fi
