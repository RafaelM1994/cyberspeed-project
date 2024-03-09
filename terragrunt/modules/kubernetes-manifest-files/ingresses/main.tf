terraform {
  required_version = ">= 1.3.9"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}


resource "kubernetes_ingress" "this" {

  for_each = var.kubernetes_ingress
  
  metadata {
    name = each.value.name
  }

  spec {
    backend {
      service_name = each.value.service_name
      service_port = each.value.service_port
    }

    rule {
      http {
        path {
          backend {
            service_name = each.value.service_name
            service_port = each.value.service_port
          }

          path = each.value.path
        }

      }
    }
  }
}
