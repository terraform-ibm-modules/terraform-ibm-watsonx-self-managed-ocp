# Cloud Pak Deployer module

A module to deploy Cloud Pak for Data onto a Red Hat OpenShift cluster using the Cloud Pak Deployer Helm chart.

### Usage

```hcl
module "cloud_pak_deployer" {
  source                     = "terraform-ibm-modules/watsonx-self-managed-ocp/ibm//modules/cloud-pak-deployer"
  version                    = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  cluster_name               = "my-ocp-cluster"
  cloud_pak_deployer_config  = var.cloud_pak_deployer_config
  cpd_entitlement_key        = var.cpd_entitlement_key
  cpd_admin_password         = var.cpd_admin_password # pragma: allowlist secret
  cpd_accept_license         = true
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.1.0, <4.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.cloud_pak_deployer_helm_release](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_pak_deployer_config"></a> [cloud\_pak\_deployer\_config](#input\_cloud\_pak\_deployer\_config) | Object definition of the Cloud Pak Deployer configuration | `any` | n/a | yes |
| <a name="input_cloud_pak_deployer_image"></a> [cloud\_pak\_deployer\_image](#input\_cloud\_pak\_deployer\_image) | The cloud pak deployer image location | `string` | `null` | no |
| <a name="input_cloud_pak_deployer_secret"></a> [cloud\_pak\_deployer\_secret](#input\_cloud\_pak\_deployer\_secret) | Image pull secret for the cloud pak deployer image | <pre>object({<br/>    username = string<br/>    password = string # pragma: allowlist secret<br/>    server   = string<br/>    email    = string<br/>  })</pre> | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of Red Hat OpenShift cluster to install watsonx onto | `string` | n/a | yes |
| <a name="input_cpd_accept_license"></a> [cpd\_accept\_license](#input\_cpd\_accept\_license) | When set to 'true', it is understood that the user has read the terms of the Cloud Pak license(s) and agrees to the terms outlined | `bool` | `false` | no |
| <a name="input_cpd_admin_password"></a> [cpd\_admin\_password](#input\_cpd\_admin\_password) | Password to be used by the admin user to access the Cloud Pak for Data UI. | `string` | n/a | yes |
| <a name="input_cpd_entitlement_key"></a> [cpd\_entitlement\_key](#input\_cpd\_entitlement\_key) | Cloud Pak for Data entitlement key for access to the IBM Entitled Registry. Can be fetched from https://myibm.ibm.com/products-services/containerlibrary. | `string` | n/a | yes |
| <a name="input_rollback_on_failure"></a> [rollback\_on\_failure](#input\_rollback\_on\_failure) | Flag to automatically rollback the helm chart on installation failure. | `bool` | `true` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
