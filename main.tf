terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.1.0"
    }
  }
}
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-user9"
    storage_account_name = "cojarobietuuu"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

data "azurerm_user_assigned_identity" "identity_data" {
  name                = "Kamil_Managed_identity"
  resource_group_name = "rg-user9"
}

# 2. Moduł Key Vaulta (zostaje bez zmian, ale pilnuj klamry na końcu!)
module "keyvault" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=keyvault/v1.0.0"
  keyvault_name = "kamilvuser9"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

# 3. Sekret (używamy poprawnego vault_id)
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  value        = "Server=tcp:${module.mssql_server.server.fully_qualified_domain_name},1433;Initial Catalog=webappdb;Persist Security Info=False;User ID=sqladmin;Password=mojeSuperHaslo123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = module.keyvault.vault_id # <--- POPRAWIONE NA vault_id
}

# 4. Polisa dostępu (używamy danych z Data Source)
resource "azurerm_key_vault_access_policy" "app_service_policy" {
  key_vault_id = module.keyvault.vault_id # <--- POPRAWIONE NA vault_id
  tenant_id    = data.azurerm_user_assigned_identity.identity_data.tenant_id
  object_id    = data.azurerm_user_assigned_identity.identity_data.principal_id

  secret_permissions = ["Get"]
}

module "managed_identity" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=managed_identity/v1.0.0"
  name = "Kamil_Managed_identity"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
}

module "service_plan" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=service_plan/v2.0.0"
  app_service_plan_name = "KamilAppServicePlan"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
sku_name = "B1"
tags = {
    Environment = "Dev"
    Owner       = "Kamil"
    Project     = "GlobalAzure2026"
  }
}

module "mssql_server" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=mssql_server/v1.0.0"
  
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }

  sql_server_name    = "sql-kamil-user9" 
  sql_server_admin   = "sqladmin"
  sql_server_version = "12.0" # Dodany wymagany argument
}
resource "azurerm_mssql_database" "webappdb" {
  name           = "webappdb"
  server_id      = module.mssql_server.server.id
  sku_name       = "Basic" # Najtańsza opcja na warsztaty
  storage_account_type = "Local"
}

module "application_insights" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=application_insights/v1.0.0"
  application_insights_name = "smartappKamilhouse"
  log_analytics_name = "kamilloganalyticsworkspace"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
}

module "app_service" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=app_service/v1.0.0"
  app_service_name = "kamil-webapp-unique"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
  app_service_plan_id = module.service_plan.app_service_plan.id
  identity_id        = module.managed_identity.managed_identity_id
  identity_client_id  = module.managed_identity.managed_identity_client_id 
  app_settings = {
    "INSTRUMENTATION_KEY" = module.application_insights.instrumentation_key
    "WEBSITES_PORT" = "8080"
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = "1800"
    "ConnectionStrings__RazorPagesMovieContext" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection_string.versionless_id})"
    "DB_SERVER"   = module.mssql_server.server.fully_qualified_domain_name
    "DB_NAME"     = "webappdb"
    "DB_USER"     = "sqladmin"
    "DB_PASSWORD" = "mojeSuperHaslo123!"
  }
}

module "container_registry" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=container_registry/v1.0.0"
  container_registry_name = "Containerregistrykamil"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
}
