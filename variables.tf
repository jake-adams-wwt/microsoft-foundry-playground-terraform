variable "location" {
  type        = string
  description = "Azure Region"
}

variable "product_name" {
  type = string
}

variable "standard_tags" {
  type = map(any)

  default = {
    Environment = "Production"
    Dept        = "Engineering"
    Billing     = "<Billing code>"
    Product     = "Azure ExpressRoute"
  }
}
