resource "azurerm_container_group" "agents" {
  name                = "example-continst"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  ip_address_type     = "Public"
  dns_name_label      = "tfcagent"
  os_type             = "Linux"

  container {
    name   = "container-tfcagent-demo-weu"
    image  = "docker.io/hashicorp/tfc-agent:latest"
    cpu    = "0.5"
    memory = "1.5"

    secure_environment_variables = {
      "TFC_AGENT_TOKEN" = "${var.TFC_AGENT_TOKEN}"
      "TFC_AGENT_NAME"  = "${var.TFC_AGENT_NAME}"
    }

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 7146
      protocol = "TCP"
    }
  }
}