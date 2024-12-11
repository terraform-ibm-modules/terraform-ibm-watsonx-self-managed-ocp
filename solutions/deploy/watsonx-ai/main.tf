locals {
  cloud_pak_deployer_watsonx_ai_config = {
    cartridges = [
      {
        description = "watsonx.ai"
        name        = "watsonx_ai"
        state       = var.watsonx_ai_install ? "installed" : "removed"
        models = [
          for model in local.watsonx_ai_models_available : {
            model_id = model
            state    = contains(var.watsonx_ai_models, model) && var.watsonx_ai_install ? "installed" : "removed"
          }
        ]
      },
      {
        description = "Watson Assistant"
        name        = "watson-assistant"
        size        = "small"
        state       = var.watson_assistant_install ? "installed" : "removed"
      },
      {
        description = "Watson Discovery"
        name        = "watson-discovery"
        state       = var.watson_discovery_install ? "installed" : "removed"
      }
    ]
  }
  watsonx_ai_models_available = ["google-flan-t5-xxl", "google-flan-ul2", "eleutherai-gpt-neox-20b", "ibm-granite-13b-chat-v1", "ibm-granite-13b-instruct-v1", "meta-llama-llama-2-70b-chat", "ibm-mpt-7b-instruct2", "bigscience-mt0-xxl", "bigcode-starcoder", "ibm-granite-13b-chat-v2", "meta-llama-llama-3-8b-instruct"]
}
