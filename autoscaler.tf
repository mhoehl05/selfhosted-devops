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

resource "azurerm_container_app" "acr_autoscaler" {
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

      env {
        name  = "SUBSCRIPTION_ID"
        value = var.subscription_id
      }

      env {
        name  = "GROUP_NAME"
        value = data.azurerm_resource_group.devops_rg.name
      }

      env {
        name  = "REGISTRIES"
        value = azurerm_container_registry.base_acr.name
      }

      env {
        name  = "AGENT_POOL"
        value = azurerm_container_registry_agent_pool.acr_agents.name
      }

      env {
        name  = "AZURE_TENANT_ID"
        value = var.tenant_id
      }

      env {
        name  = "AZURE_CLIENT_ID"
        value = var.client_id
      }

      env {
        name        = "AZURE_CLIENT_SECRET"
        secret_name = "service-principal-password"
      }
    }

    secret {
      name  = "service-principal-password"
      value = var.client_secret
    }
  }

  depends_on = [
    azurerm_container_registry_task_schedule_run_now.build_autoscaler,
    azurerm_role_assignment.autoscaler_image_pull
  ]
}