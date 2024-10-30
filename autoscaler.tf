resource "azurerm_storage_account" "autoscaler_stacc" {
  name                     = "staccacragentautoscaler"
  location                 = data.azurerm_resource_group.devops_rg.location
  resource_group_name      = data.azurerm_resource_group.devops_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "autoscaler_service_plan" {
  name                = "appsp-acragent-autoscaler-demo-weu"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "autoscaler_function_app" {
  name                = "funcapp-acragent-autoscaler-demo-weu"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  app_service_plan_id = azurerm_app_service_plan.autoscaler_service_plan.id

  storage_account_name       = azurerm_storage_account.autoscaler_stacc.name
  storage_account_access_key = azurerm_storage_account.autoscaler_stacc.primary_access_key

  zip_deploy_file = data.archive_file.acr_autoscaler_function.output_path

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
}