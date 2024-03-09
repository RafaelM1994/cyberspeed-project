terraform {
  required_version = ">= 1.3.9"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}


resource "kubernetes_namespace" "this" {
  for_each = var.namespaces

  metadata {

    name = each.value.name

    labels = {
      environment = each.value.environment
    }
  }
}
