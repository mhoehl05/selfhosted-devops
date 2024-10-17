resource "azurerm_container_registry_agent_pool" "acr_agents" {
  name                      = "base-acr-agentpool"
  resource_group_name       = data.azurerm_resource_group.devops_rg.name
  location                  = data.azurerm_resource_group.devops_rg.location
  container_registry_name   = azurerm_container_registry.base_acr.name
  instance_count            = 1
  tier                      = "S1"
  virtual_network_subnet_id = azurerm_subnet.acr_agents.id
}

resource "azurerm_container_registry_task" "pull_tfcagent" {
  name                  = "pull-tfcagent-image"
  container_registry_id = azurerm_container_registry.base_acr.id
  agent_pool_name       = azurerm_container_registry_agent_pool.acr_agents.name

  platform {
    os = "Linux"
  }

  file_step {
    task_file_path = "${path.module}/tasks/acragents/task.yaml"
    context_path   = "${path.module}/tasks/acragents"
    values = {
      "REGISTRY_FROM_URL" = "docker.io"
    }
  }
}

resource "azurerm_container_registry_task_schedule_run_now" "pull_tfcagent" {
  container_registry_task_id = azurerm_container_registry_task.pull_tfcagent.id
}