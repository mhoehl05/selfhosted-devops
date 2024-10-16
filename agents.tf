locals {
  agents = [
    {
      cpu    = "0.5"
      memory = "1.5"
    },
    {
      cpu    = "0.5"
      memory = "1.5"
    },
    {
      cpu    = "0.5"
      memory = "1.5"
    }
  ]
}


resource "azurerm_container_group" "agents" {
  name                = "continst-tfcagent-demo-weu"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = ["${azurerm_subnet.agents.id}"]

  dynamic "container" {
    for_each = local.agents

    content {
      name   = "container-tfcagent-demo-weu-${index(local.agents, container.value) + 1}"
      image  = "docker.io/hashicorp/tfc-agent:latest"
      cpu    = container.value.cpu
      memory = container.value.memory

      secure_environment_variables = {
        "TFC_AGENT_TOKEN" = "${var.TFC_AGENT_TOKEN}"
        "TFC_AGENT_NAME"  = "${var.TFC_AGENT_NAME}-${index(local.agents, container.value) + 1}"
      }

      ports {
        port     = 22
        protocol = "TCP"
      }
    }
  }
}