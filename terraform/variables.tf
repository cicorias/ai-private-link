variable "azure_resource_base_name" {
  description = "The base name for caf generated resources names."
  type        = string
  default     = "demogroup"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  type        = string
  default     = "westus3"
}

variable "tags" {
  description = "The tags to associate with your resources."
  type        = map(string)
  default = {
    environment = "development"
  }
}
 