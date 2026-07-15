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

# resource "random_password" "sql_password" {
#   length           = 16
#   special          = true
#   override_special = "!#$%&*()-_=+[]{}<>:?"
# }

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

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-client-a-prod-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "app_insights" {
  name                = "appi-client-a-prod-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
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
      # Instead of the secret, we just tell the app where the Vault is!
    "KeyVaultUri" = azurerm_key_vault.vault.vault_uri
    # Use "Active Directory Default" for passwordless auth
    "ConnectionStrings__DefaultConnection" = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_db.name};Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Default;"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.app_insights.connection_string
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
  # administrator_login_password = random_password.sql_password.result

  azuread_administrator {
    login_username = "melek.ferhi@gmail.com"
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id

    # THIS IS THE KEY: It removes the password requirement
    azuread_authentication_only = true
  }

  lifecycle {
  ignore_changes = [administrator_login_password]
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


# 2. Create the Vault
resource "azurerm_key_vault" "vault" {
  name                = "kv-client-a-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# Grant YOURSELF access to manage secrets
resource "azurerm_key_vault_access_policy" "your_user_access" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id # This is your user ID

  secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
}

# 3. Grant the Web App access to read secrets
resource "azurerm_key_vault_access_policy" "web_app_access" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.web_app.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}