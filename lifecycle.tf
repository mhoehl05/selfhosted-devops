resource "azurerm_container_registry_agent_pool" "acr_agents" {
  name                      = "acragentpool-imagelifecycle-demo-weu"
  resource_group_name       = data.azurerm_resource_group.devops_rg.name
  location                  = data.azurerm_resource_group.devops_rg.location
  container_registry_name   = azurerm_container_registry.base_acr.name
  instance_count            = 1
  tier                      = "S1"
  virtual_network_subnet_id = azurerm_subnet.acr_agents.id
}