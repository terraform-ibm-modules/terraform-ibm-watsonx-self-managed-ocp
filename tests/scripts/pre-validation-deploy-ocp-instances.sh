#! /bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the OCP instances,
## which are the prerequisites for the SCC workload protection standard fullstack.
############################################################################################################

set -e

DA_DIR="solutions/standard"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite OCP instances .."
  terraform init || exit 1
  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "region=\"${REGION}\""
    echo "prefix=\"ocp-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  region_var_name="region"
  prefix_var_name="prefix"
  prefix_value="ocp-$(openssl rand -hex 2)"
  cpd_entitlement_key_var_name="cpd_entitlement_key"
  cpd_entitlement_key_value="${SOFTWARE_ENTITLEMENT_KEY}"
  existing_cluster_name_var_name="existing_cluster_name"
  existing_cluster_name_value=$(terraform output -state=terraform.tfstate -raw cluster_name)
  existing_resource_group_name_var_name="existing_resource_group_name"
  existing_resource_group_name_value=$(terraform output -state=terraform.tfstate -raw cluster_resource_group_name)

  echo "Appending '${existing_cluster_name_var_name}', '${existing_resource_group_name_var_name}', '${cpd_entitlement_key_var_name}', and '${region_var_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg region_var_name "${region_var_name}" \
        --arg region_var_value "${REGION}" \
        --arg prefix_var_name "${prefix_var_name}" \
        --arg prefix_value "${prefix_value}" \
        --arg cpd_entitlement_key_var_name "${cpd_entitlement_key_var_name}" \
        --arg cpd_entitlement_key_value "${cpd_entitlement_key_value}" \
        --arg existing_cluster_name_var_name "${existing_cluster_name_var_name}" \
        --arg existing_cluster_name_value "${existing_cluster_name_value}" \
        --arg existing_resource_group_name_var_name "${existing_resource_group_name_var_name}" \
        --arg existing_resource_group_name_value "${existing_resource_group_name_value}" \
        '. + {($region_var_name): $region_var_value, ($prefix_var_name): $prefix_value, ($cpd_entitlement_key_var_name): $cpd_entitlement_key_value, ($existing_cluster_name_var_name): $existing_cluster_name_value, ($existing_resource_group_name_var_name): $existing_resource_group_name_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
