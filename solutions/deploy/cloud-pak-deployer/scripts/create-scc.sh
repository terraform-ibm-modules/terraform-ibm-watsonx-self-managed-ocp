#!/bin/bash

${OC} adm policy add-scc-to-user "${SECURITY_CONTEXT_CONSTRAINT_NAME}" -z "${SERVICE_ACCOUNT_NAME}" -n "${NAMESPACE_NAME}"
RC=$?

if [ "${RC}" -ne 0 ]; then echo "Error adding scc ${SECURITY_CONTEXT_CONSTRAINT_NAME} to service acount ${SERVICE_ACCOUNT_NAME}; exiting..." && exit 1; fi

exit 0;
