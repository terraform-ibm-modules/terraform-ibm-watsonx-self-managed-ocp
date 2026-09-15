# watsonx.data module

A module that generates the Cloud Pak Deployer configuration for the watsonx.data cartridge.

### Usage

```hcl
module "watsonx_data" {
  source               = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//modules/watsonx-data"
  version              = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  watsonx_data_install = true
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
| <a name="input_watsonx_data_install"></a> [watsonx\_data\_install](#input\_watsonx\_data\_install) | Determine whether the watsonx.data cartridge for the deployer will be installed | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_watsonx_data_cloud_pak_deployer_config"></a> [watsonx\_data\_cloud\_pak\_deployer\_config](#output\_watsonx\_data\_cloud\_pak\_deployer\_config) | Cloud Pak Deployer configuration corresponding to the watsonx.data cartridge |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
