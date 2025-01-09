locals {
  cloud_pak_deployer_watsonx_data_config = {
    cartridges = [
      {
        description = "watsonx.data"
        name        = "watsonx_data"
        state       = var.watsonx_data_install ? "installed" : "removed"
      }
    ]
  }
}

# TODO: Add check for required storage class(es)
