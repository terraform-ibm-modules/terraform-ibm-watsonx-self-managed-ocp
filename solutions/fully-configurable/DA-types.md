# Variable: `cloud_pak_deployer_secret`

## Overview

The `cloud_pak_deployer_secret` variable is used to provide credentials for accessing a private Cloud Pak Deployer image registry. This is required if you are using a custom or private image that is not publicly accessible. If this variable is set to `null`, a default secret will be created automatically.

## Variable Definition

```hcl
variable "cloud_pak_deployer_secret" {
  description = "Secret for accessing the Cloud Pak Deployer image. If `null`, a default secret will be created # pragma: allowlist secret."
  type = object({
    username = string
    password = string
    server   = string
    email    = string
  })
  default = null
}
```

## Usage

The value should be an object with the following fields:

- `username`: The username for the container registry.
- `password`: The password or token for the container registry.
- `server`: The registry server URL (e.g., `quay.io`, `icr.io`, etc.).
- `email`: The email address associated with the registry account.

### Example

```hcl
cloud_pak_deployer_secret = {
  username = "my-registry-user"
  password = "my-registry-password"  # pragma: allowlist secret
  server   = "quay.io"
  email    = "user@example.com"
}
```

If you are using IBM Cloud Container Registry (ICR), your `server` might look like `us.icr.io` or `de.icr.io`.

### When to Use

- **Required**: When your `cloud_pak_deployer_image` is hosted in a private registry that requires authentication.
- **Optional**: If using the default public image, you can leave this variable as `null`.

## References

- [IBM Cloud Pak Deployer Documentation](https://github.com/IBM/cloud-pak-deployer)
- [IBM Cloud Container Registry Docs](https://cloud.ibm.com/docs/container-registry)
- [Terraform Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)

## Example usage

```hcl
cloud_pak_deployer_secret = {
  username = "myuser"
  password = "mypassword"  # pragma: allowlist secret
  server   = "us.icr.io"
  email    = "myuser@example.com"
}
```

> **Note:** If you do not need a custom image or private registry, you can omit this variable or set it to `null`.
