resource "azurerm_container_registry" "agent_acr" {
  name                = "acr-tfcagents-demo-weu"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  location            = data.azurerm_resource_group.devops_rg.location
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Deny"
  }
}

resource "azurerm_private_endpoint" "acr_pep" {
  name                = "pep-acr-demo-weu"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  location            = data.azurerm_resource_group.devops_rg.location
  subnet_id           = azurerm_subnet.system.id

  private_service_connection {
    name                           = "pepconn-acr-demo-weu"
    private_connection_resource_id = azurerm_container_registry.agent_acr.id
    is_manual_connection           = false
  }
}

data "azurerm_network_interface" "acr_nic" {
  name                = azurerm_private_endpoint.acr_pep.network_interface[0].name
  resource_group_name = data.azurerm_resource_group.devops_rg.name

  depends_on = [
    azurerm_private_endpoint.acr_pep
  ]
}

resource "azurerm_private_dns_zone" "acr_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.devops_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_link" {
  name                  = "dnslinkacrdemoweu"
  resource_group_name   = data.azurerm_resource_group.devops_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = azurerm_virtual_network.devops_vnet.id

resource "azurerm_private_dns_a_record" "pep_dns_record_data" {
  name                = lower(format("%s.%s.data", azurerm_container_registry.agent_acr.name, data.azurerm_resource_group.devops_rg.location))
  zone_name           = azurerm_private_dns_zone.acr_dns.name
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  ttl                 = 3600
  records             = [data.azurerm_network_interface.acr_nic.private_ip_addresses[0]]
}

resource "azurerm_private_dns_a_record" "pep_dns_record" {
  name                = lower(azurerm_container_registry.agent_acr.name)
  zone_name           = azurerm_private_dns_zone.acr_dns.name
  resource_group_name = data.azurerm_resource_group.devops_rg.name
  ttl                 = 3600
  records             = [data.azurerm_network_interface.acr_nic.private_ip_addresses[1]]
}