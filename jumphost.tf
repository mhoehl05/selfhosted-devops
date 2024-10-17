module "jumphost" {
  source = "git::https://github.com/mhoehl05/basic-jumphost.git?ref=main"

  rg_name         = data.azurerm_resource_group.devops_rg.name
  snet_id         = azurerm_subnet.system.id
  public_key_path = "${path.module}/ssh_keys/id_rsa_mark.pub"
}