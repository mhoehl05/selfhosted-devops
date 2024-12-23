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

  encoded_step {
    task_content = <<EOF
    version: v1.1.0
    steps:
      - id: pull-tfcagent-image
        cmd: >
          docker pull {{.Values.REGISTRY_FROM_URL}}/hashicorp/tfc-agent:latest
      - id: retag-tfcagent-image
        when: ['pull-tfcagent-image']
        cmd: docker tag {{.Values.REGISTRY_FROM_URL}}/hashicorp/tfc-agent:latest {{.Run.Registry}}/hashicorp/tfc-agent:latest
      - id: push-tfcagent-image
        when: ['retag-tfcagent-image']
        push:
        - "{{.Run.Registry}}/hashicorp/tfc-agent:latest"
    EOF
    context_path = "/dev/null"
    values = {
      "REGISTRY_FROM_URL" = "${var.public_registry}"
    }
  }
}

resource "azurerm_container_registry_task_schedule_run_now" "pull_tfcagent" {
  container_registry_task_id = azurerm_container_registry_task.pull_tfcagent.id
  depends_on = [
    azurerm_private_dns_a_record.pep_dns_record,
    azurerm_private_dns_a_record.pep_dns_record_data
  ]
}

resource "azurerm_container_registry_task" "build_autoscaler" {
  name                  = "build-autoscaler-image"
  container_registry_id = azurerm_container_registry.base_acr.id
  agent_pool_name       = azurerm_container_registry_agent_pool.acr_agents.name

  platform {
    os = "Linux"
  }

  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://github.com/mhoehl05/acr-agent-autoscaler#main"
    context_access_token = var.github_token
    image_names          = ["acr-agent-autoscaler:latest"]
  }
}

resource "azurerm_container_registry_task_schedule_run_now" "build_autoscaler" {
  container_registry_task_id = azurerm_container_registry_task.build_autoscaler.id
  depends_on = [
    azurerm_private_dns_a_record.pep_dns_record,
    azurerm_private_dns_a_record.pep_dns_record_data
  ]
}