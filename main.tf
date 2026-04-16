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

module "keyvault" {
  source = "git::https://github.com/pchylak/global_azure_2026_ccoe.git?ref=keyvault/v1.0.0"
  keyvault_name = "kamilvuser9"
  resource_group = {
    name     = "rg-user9"
    location = "polandcentral" 
  }
network_acls = {
  default_action = "Deny"
  bypass = "AzureServices"
  }
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
  sql_server_admin = "KamilAdmin"
  sql_server_name = "MySQLKamilDatabase"
  sql_server_version = "12.0"
}
