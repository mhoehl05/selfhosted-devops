resource "azurerm_storage_account" "state_deposit" {
  name                     = "staccdefaultstatedeposit"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "state_container" {
  name                  = "statefiles"
  storage_account_name  = azurerm_storage_account.state_deposit.name
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "default" {
  storage_account_id = azurerm_storage_account.state_deposit.id

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.agents.id]
  bypass                     = ["AzureServices"]
}