resource "azurerm_virtual_network_peering" "hub" {
  name                      = "peerhubtodevops"
  resource_group_name       = data.azurerm_resource_group.devops_rg.name
  virtual_network_name      = data.azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.devops_vnet.id
}

resource "azurerm_virtual_network_peering" "devops" {
  name                      = "peerdevopstohub"
  resource_group_name       = data.azurerm_resource_group.devops_rg.name
  virtual_network_name      = azurerm_virtual_network.devops_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet.id
}