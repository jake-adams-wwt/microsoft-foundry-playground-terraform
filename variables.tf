variable "location" {
  type        = string
  description = "Azure Region"
}

variable "product_name" {
  type    = string
  default = "Foundry Playground"
}

variable "standard_tags" {
  type = map(any)
}
