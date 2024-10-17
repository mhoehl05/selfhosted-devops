resource "azurerm_user_assigned_identity" "tfcagent_identity" {
  location            = data.azurerm_resource_group.devops_rg.location
  name                = "idcontapp-tfcagent-demo-weu"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
}

resource "azurerm_role_assignment" "image_pull" {
  scope                = azurerm_container_registry.base_acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.tfcagent_identity.principal_id
}

resource "azurerm_log_analytics_workspace" "tfcagent_logs" {
  name                = "tfcagents-01"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "tfcagent_env" {
  name                       = "contenv-tfcagents-demo-weu"
  location                   = data.azurerm_resource_group.devops_rg.location
  resource_group_name        = data.azurerm_resource_group.devops_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.tfcagent_logs.id
}

resource "azurerm_container_app" "agents" {
  name                         = "contapp-tfcagents-demo-weu"
  container_app_environment_id = azurerm_container_app_environment.tfcagent_env.id
  resource_group_name          = data.azurerm_resource_group.devops_rg.name
  revision_mode                = "Single"
  infrastructure_subnet_id     = azurerm_subnet.TfcAgentSubnet.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.tfcagent_identity.id]
  }

  registry {
    server   = azurerm_container_registry.base_acr.login_server
    identity = azurerm_user_assigned_identity.tfcagent_identity.id
  }

  template {
    container {
      name   = "tfcagent"
      image  = "${azurerm_container_registry.base_acr.login_server}/hashicorp/tfc-agent:latest"
      cpu    = 1.0
      memory = "2.0Gi"

      env {
        name  = "TFC_AGENT_TOKEN"
        value = var.TFC_AGENT_TOKEN
      }

      env {
        name  = "TFC_AGENT_NAME"
        value = var.TFC_AGENT_NAME
      }
    }
  }

  depends_on = [
    azurerm_container_registry_task_schedule_run_now.pull_tfcagent,
    azurerm_role_assignment.image_pull
  ]
}