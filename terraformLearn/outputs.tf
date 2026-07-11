output "resource_group_id" {
  description = "The Azure ID of the Resource Group"
  value       = azurerm_resource_group.rg.id
}

output "root_subnet_id" {
  description = "The Subnet ID exported via the module"
  value       = module.network_stack.subnet_id
} 