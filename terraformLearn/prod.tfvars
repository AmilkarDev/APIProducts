resource_group_name       = "rg-client-a-prod"
environment               = "prod"
location                  = "West Europe"
vnet_address_space        = ["10.20.0.0/16"]
subnet_address_prefixes   = ["10.20.1.0/24"]
sql_entra_admin_login     = "terraform-piepline-sp"
sql_entra_admin_object_id = "f17a7be0-7ba7-475e-8967-cb4654837171"
