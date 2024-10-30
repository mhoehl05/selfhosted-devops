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
  service_plan_id     = azurerm_service_plan.autoscaler_service_plan.id

  storage_account_name       = azurerm_storage_account.autoscaler_stacc.name
  storage_account_access_key = azurerm_storage_account.autoscaler_stacc.primary_access_key

  webdeploy_publish_basic_authentication_enabled = true

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  github {

  }

  depends_on = [
    azurerm_container_registry_task_schedule_run_now.pull_tfcagent
  ]
}

resource "azurerm_app_service_source_control" "autoscaler_function_source" {
  app_id   = azurerm_linux_web_app.autoscaler_function_app.id
  repo_url = "https://github.com/mhoehl05/acr-agent-autoscaler"
  branch   = "main"
}
