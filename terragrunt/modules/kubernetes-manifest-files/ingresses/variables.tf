variable "kubernetes_ingress" {
  type = map(object({
    name         = string
    service_name = string
    service_port = number
    path         = string
    environment  = string
  }))
  
}