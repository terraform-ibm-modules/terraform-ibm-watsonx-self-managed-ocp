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
  watsonx_ai_models_available = [
    "allam-1-13b-instruct",
    "codellama-codellama-34b-instruct-hf",
    "elyza-japanese-llama-2-7b-instruct",
    "google-flan-t5-xl", "google-flan-t5-xxl",
    "google-flan-ul2",
    "ibm-granite-7b-lab",
    "ibm-granite-8b-japanese",
    "ibm-granite-13b-chat-v2",
    "ibm-granite-13b-instruct-v2",
    "ibm-granite-20b-multilingual",
    "granite-3b-code-instruct",
    "granite-8b-code-instruct",
    "granite-20b-code-instruct",
    "granite-34b-code-instruct",
    "core42-jais-13b-chat",
    "meta-llama-llama-2-13b-chat",
    "mncai-llama-2-13b-dpo-v7",
    "llama-3-1-8b-instruct",
    "llama-3-1-70b-instruct",
    "llama-3-405b-instruct",
    "meta-llama-llama-3-8b-instruct",
    "meta-llama-llama-3-70b-instruct",
    "ibm-mistralai-merlinite-7b",
    "bigscience-mt0-xxl"
  ]
}
