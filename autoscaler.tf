resource "azurerm_user_assigned_identity" "autoscaler_identity" {
  location            = data.azurerm_resource_group.devops_rg.location
  name                = "idcontapp-system-demo-weu"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
}

resource "azurerm_role_assignment" "autoscaler_image_pull" {
  scope                = azurerm_container_registry.base_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.autoscaler_identity.principal_id
}

resource "azurerm_log_analytics_workspace" "autoscaler_logs" {
  name                = "autoscaler-01"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "autoscaler_env" {
  name                       = "contenv-autoscaler-demo-weu"
  location                   = data.azurerm_resource_group.devops_rg.location
  resource_group_name        = data.azurerm_resource_group.devops_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.autoscaler_logs.id
  infrastructure_subnet_id   = azurerm_subnet.system.id
}

resource "azurerm_container_app" "agents" {
  name                         = "contapp-autoscaler-demo-weu"
  container_app_environment_id = azurerm_container_app_environment.autoscaler_env.id
  resource_group_name          = data.azurerm_resource_group.devops_rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.autoscaler_identity.id]
  }

  registry {
    server   = azurerm_container_registry.base_acr.login_server
    identity = azurerm_user_assigned_identity.autoscaler_identity.id
  }

  template {
    container {
      name   = "acr-agent-autoscaler"
      image  = "${azurerm_container_registry.base_acr.login_server}/acr-agent-autoscaler:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  depends_on = [
    azurerm_container_registry_task_schedule_run_now.build_autoscaler,
    azurerm_role_assignment.autoscaler_image_pull
  ]
}