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

variable "create_bastion" {
    description = "Create a bastion host."
    type        = bool
    default     = true
}

variable "create_aks_cluster" {
    description = "Create an aks cluser."
    type        = bool
    default     = true
}

variable "admin_username" {
  description = "The username of the local administrator to create on the Virtual Machine."
  type        = string
  default     = "azureuser"
}

variable "tags" {
  description = "The tags to associate with your resources."
  type        = map(string)
  default = {
    environment = "development"
  }
}
 
variable "node_count" {
  description = "The number of nodes in the Kubernetes cluster."
  type        = number
  default     = 1
}