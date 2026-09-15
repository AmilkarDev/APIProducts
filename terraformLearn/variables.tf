variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for the resources"
  type        = string
  default     = "West Europe"
}
variable "environment" {
  type        = string
  description = "The target environment (e.g., dev, prod, staging)"
}

variable "vnet_address_space" {
  description = "The address space assigned to the environment virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "The address prefixes assigned to the backend subnet"
  type        = list(string)
}

variable "sql_entra_admin_login" {
  description = "Display name of the stable Microsoft Entra administrator for Azure SQL"
  type        = string
}

variable "sql_entra_admin_object_id" {
  description = "Object ID of the stable Microsoft Entra administrator for Azure SQL"
  type        = string
}
