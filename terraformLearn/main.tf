terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-meta"
    storage_account_name = "amallokstorage" # Must match your step 1 name
    container_name       = "tfstate"
    key                  = "client-a-dev.terraform.tfstate" # The name of the blob file in Azure
  }

}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "Terraform Getting Started"
    team        = "DevOps"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "azurerm_service_plan" "app_plan" {
  name                = "app-plan-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "web_app" {
  name                      = "app-client-a-dotnet-api-${random_string.suffix.result}"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  service_plan_id           = azurerm_service_plan.app_plan.id
  virtual_network_subnet_id = module.network_stack.subnet_id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ConnectionStrings__DefaultConnection" = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_db.name};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Default;"
  }

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
  }
}


resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-client-a-prod-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_password.result

  azuread_administrator {
    login_username = "melek.ferhi@gmail.com"
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_mssql_database" "sql_db" {
  name      = "sqldb-client-a-prod"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic" # Keeping costs low for this tutorial!
}

resource "azurerm_mssql_firewall_rule" "local_access" {
  name             = "Local-Dev-Access"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "176.128.237.100"
  end_ip_address   = "176.128.237.100"
}


resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = module.network_stack.subnet_id
}

# 2. L'instanciation du module
module "network_stack" {
  source = "./modules/azure_network" # Le chemin vers ta "Class Library"

  # Injection des dépendances et variables
  rg_name     = azurerm_resource_group.rg.name
  location    = azurerm_resource_group.rg.location
  vnet_name   = "vnet-client-a-prod"
  subnet_name = "snet-backend-prod"
}
