resource "azurerm_virtual_network" "devops_vnet" {
  name                = "vnet-devops-demo-weu"
  address_space       = ["10.1.0.0/16"]
  location            = data.azurerm_resource_group.devops_rg.location
  resource_group_name = data.azurerm_resource_group.devops_rg.name
}

resource "azurerm_subnet" "tfc_agents" {
  name                 = "TfcAgentSubnet"
  resource_group_name  = data.azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.1.0.0/23"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "acr_agents" {
  name                 = "AcrAgentSubnet"
  resource_group_name  = data.azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.1.2.0/23"]
}

resource "azurerm_subnet" "system" {
  name                 = "SystemSubnet"
  resource_group_name  = data.azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.1.4.0/23"]
}

resource "azurerm_storage_account_network_rules" "default" {
  storage_account_id = data.azurerm_storage_account.state_deposit.id

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.tfc_agents.id]
  bypass                     = ["AzureServices"]
}
