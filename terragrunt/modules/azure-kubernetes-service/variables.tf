variable "kubernetes_clusters" {
  type = map(object({
    environment             = string
    name                    = string
    location                = string
    resource_group_name     = string
    container_registry_name = string
    container_registry_sku  = string

  }))
}
