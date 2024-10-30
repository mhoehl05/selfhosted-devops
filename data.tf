data "azurerm_resource_group" "devops_rg" {
  name = "rg-devops-demo-weu"
}

data "azurerm_storage_account" "state_deposit" {
  name                = "staccdefaultstatedeposit"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
}

data "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub-demo-weu"
  resource_group_name = "rg-hubnetwork-demo-weu"
}