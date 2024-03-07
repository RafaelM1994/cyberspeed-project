terraform {
  required_version = ">= 1.3.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.93.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  for_each = var.kubernetes_clusters
  name     = each.value.resource_group_name
  location = each.value.location
}

resource "azurerm_kubernetes_cluster" "this" {

  for_each            = var.kubernetes_clusters
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  dns_prefix          = each.value.name

  default_node_pool {
    name                        = "default"
    node_count                  = 1
    vm_size                     = "Standard_D2as_v4"
    type                        = "VirtualMachineScaleSets"
    temporary_name_for_rotation = "rotate"
  }


  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each              = var.kubernetes_clusters
  name                  = "pool1"
  vm_size               = "Standard_D2as_v4"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[each.value.name].id
  os_type               = "Linux"
  mode                  = "User"
}

#create an azure container registry
resource "azurerm_container_registry" "this" {
  for_each = var.kubernetes_clusters

  name                = each.value.container_registry_name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  sku                 = each.value.container_registry_sku
  admin_enabled       = true
}

#give aks cluster access to the container registry
resource "azurerm_role_assignment" "this" {
  for_each = var.kubernetes_clusters

  principal_id         = azurerm_kubernetes_cluster.this[each.value.name].identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.this[each.value.name].id
}

