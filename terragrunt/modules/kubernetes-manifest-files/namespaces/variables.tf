variable "namespaces" {
  type = map(object({
    environment = string
    name        = string
  }))
  
}