
#Select the environment you want to create the Terraform infrastructure
$env = "poc"

#create tags
$tags = @(
    "CreationDate=$(get-date)",
    "Deployedby=$(az account show --query user.name -o tsv)",
    "Description=Terraform Required Infrastructure",
    "Environment=$($env)",
    "ProvisioningTool=AzureCLI"
)

#Create a resource group
az group create --location uksouth `
    --name "$($env.toUpper())-RG-TERRAFORM" `
    --tags $tags

#Create a storage account
az storage account create `
    --name "$($env)saterraform" `
    --resource-group "$($env.toUpper())-RG-TERRAFORM" `
    --location uksouth `
    --sku Standard_LRS `
    --kind StorageV2 `
    --tags $tags

#Enable blob Versioning
az storage account blob-service-properties update `
    --resource-group "$($env.toUpper())-RG-TERRAFORM" `
    --account-name "$($env)saterraform" `
    --enable-versioning true

#Get storage account key
$account_key = $(az storage account keys list `
        --account-name "$($env)saterraform" `
        --resource-group "$($env.toUpper())-RG-TERRAFORM" `
        --query "[0].value" `
        --output tsv)
        
#Create a container for Terraform Tfstate
az storage container create `
    --name "$($env)cotfstate" `
    --account-name "$($env)saterraform" `
    --account-key "$account_key"

#Create a key Vault for secrets
az keyvault create `
    --name "$($env)-kv-terraform" `
    --resource-group "$($env.toUpper())-RG-TERRAFORM" `
    --location "uksouth" `
    --tags $tags
