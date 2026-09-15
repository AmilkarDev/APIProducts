resource_group_name       = "rg-client-a-dev"
environment               = "dev"
location                  = "West Europe"
vnet_address_space        = ["10.10.0.0/16"]
subnet_address_prefixes   = ["10.10.1.0/24"]
sql_entra_admin_login     = "terraform-piepline-sp"
sql_entra_admin_object_id = "f17a7be0-7ba7-475e-8967-cb4654837171"
