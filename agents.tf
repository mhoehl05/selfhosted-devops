data "azuread_client_config" "current" {}

resource "azuread_application" "tfcagent_app" {
  display_name = "selfhost-tfc-agents"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "tfcagent_sp" {
  client_id                    = azuread_application.tfcagent_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "tfcagent_sp_password" {
  service_principal_id = azuread_service_principal.tfcagent_sp.id
}

resource "azurerm_role_assignment" "pull_access" {
  scope              = azurerm_container_registry.base_acr.id
  role_definition_id = "acrpull"
  principal_id       = azuread_service_principal_password.tfcagent_sp_password.service_principal_id
}

resource "azurerm_container_group" "agent" {
  count = var.agent_count

  name                = "continst-tfcagent-demo-weu-${count.index + 1}"
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = ["${azurerm_subnet.tfc_agents.id}"]

  image_registry_credential {
    server   = azurerm_container_registry.base_acr.login_server
    username = azuread_service_principal_password.tfcagent_sp_password.service_principal_id
    password = azuread_service_principal_password.tfcagent_sp_password.value
  }

  container {
    name = "tfcagent"
    #image  = "${azurerm_container_registry.base_acr.login_server}/hashicorp/tfc-agent:latest"
    image  = "docker.io/hashicorp/tfc-agent:latest"
    cpu    = "0.5"
    memory = "1.5"

    secure_environment_variables = {
      "TFC_AGENT_TOKEN" = "${var.TFC_AGENT_TOKEN}"
      "TFC_AGENT_NAME"  = "${var.TFC_AGENT_NAME}-${count.index + 1}"
    }

    ports {
      port     = 22
      protocol = "TCP"
    }
  }

  depends_on = [
    azurerm_container_registry_task_schedule_run_now.pull_tfcagent,
    azurerm_role_assignment.pull_access
  ]
}