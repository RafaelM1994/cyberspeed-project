locals {
  environment = get_env("TF_VAR_ENVIRONMENT_NAME")
}

#Common Variables will be placed here
inputs = {

  environment = local.environment

  common_tags = {
  #  DeployedBy       = "${get_env("TF_VAR_AZURE_CLIENT_ID")}"
    Environment      = local.environment
    ProvisioningTool = "Terraform"
    TerraformVersion = "1.3.9"
    CreationDate     = formatdate("EEEE, DD-MMM-YY hh:mm:ss ZZZ", timestamp())
  }
}