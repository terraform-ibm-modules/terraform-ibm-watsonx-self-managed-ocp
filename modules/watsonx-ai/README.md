# watsonx.ai module

A module that generates the Cloud Pak Deployer configuration for the watsonx.ai cartridge, including optional Watson Assistant and Watson Discovery cartridges and a configurable set of foundation models.

### Usage

```hcl
module "watsonx_ai" {
  source                   = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//modules/watsonx-ai"
  version                  = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  watsonx_ai_install       = true
  watsonx_ai_models        = ["ibm-granite-13b-instruct-v2", "ibm-granite-13b-chat-v2"]
  watson_assistant_install = false
  watson_discovery_install = false
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |

### Modules

No modules.

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_watson_assistant_install"></a> [watson\_assistant\_install](#input\_watson\_assistant\_install) | If watsonx.ai is being installed, also install watson assistant | `bool` | `false` | no |
| <a name="input_watson_discovery_install"></a> [watson\_discovery\_install](#input\_watson\_discovery\_install) | If watsonx.ai is being installed, also install watson discovery | `bool` | `false` | no |
| <a name="input_watsonx_ai_install"></a> [watsonx\_ai\_install](#input\_watsonx\_ai\_install) | Determine whether the watsonx.ai cartridge for the deployer will be installed | `bool` | `false` | no |
| <a name="input_watsonx_ai_models"></a> [watsonx\_ai\_models](#input\_watsonx\_ai\_models) | List of watsonx.ai models to install.  Information on the foundation models including pre-reqs can be found here - https://www.ibm.com/docs/en/cloud-paks/cp-data/5.0.x?topic=install-foundation-models.  Use the ModelID as input | `list(string)` | <pre>[<br/>  "ibm-granite-13b-instruct-v2"<br/>]</pre> | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_watsonx_ai_cloud_pak_deployer_config"></a> [watsonx\_ai\_cloud\_pak\_deployer\_config](#output\_watsonx\_ai\_cloud\_pak\_deployer\_config) | Cloud Pak Deployer configuration corresponding to the watsonx.ai cartridge |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
