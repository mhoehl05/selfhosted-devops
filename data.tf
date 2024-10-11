data "azurerm_resource_group" "main" {
  name = "rg-devops-demo-weu"
}

data "azurerm_storage_account" "state_deposit" {
  name                = "staccdefaultstatedeposit"
  resource_group_name = data.azurerm_resource_group.main.name
}