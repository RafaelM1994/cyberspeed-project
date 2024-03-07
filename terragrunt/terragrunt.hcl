
remote_state {
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  backend = "azurerm"
  config = {
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    resource_group_name  = "${get_env("TF_VAR_TF_RESOURCE_GROUP_NAME")}"
    storage_account_name = "${get_env("TF_VAR_TF_STORAGE_ACCOUNT_NAME")}"
    container_name       = "${get_env("TF_VAR_TF_CONTAINER_NAME")}"
    subscription_id      = "${get_env("TF_VAR_AZURE_SUBSCRIPTION_ID")}"
    tenant_id            = "${get_env("TF_VAR_AZURE_TENANT_ID")}"
    client_id            = "${get_env("TF_VAR_AZURE_CLIENT_ID")}"
    client_secret        = "${get_env("TF_VAR_AZURE_CLIENT_SECRET")}"
  }

}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt" # Allow modules to override provider settings
  contents  = <<EOF
    provider "azurerm" {
        features {}
        subscription_id   = "${get_env("TF_VAR_AZURE_SUBSCRIPTION_ID")}"
        tenant_id         = "${get_env("TF_VAR_AZURE_TENANT_ID")}"
        client_id         = "${get_env("TF_VAR_AZURE_CLIENT_ID")}"
        client_secret     = "${get_env("TF_VAR_AZURE_CLIENT_SECRET")}"

    }
EOF
}
