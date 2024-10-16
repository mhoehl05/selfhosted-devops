resource "azurerm_virtual_network" "main" {
  name                = "vnet-devops-demo-weu"
  address_space       = ["10.1.0.0/23"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_subnet" "agents" {
  name                 = "DevopsAgentSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/27"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "system" {
  name                 = "SystemSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.32/27"]
}

resource "azurerm_storage_account_network_rules" "default" {
  storage_account_id = data.azurerm_storage_account.state_deposit.id

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.agents.id]
  bypass                     = ["AzureServices"]
}
