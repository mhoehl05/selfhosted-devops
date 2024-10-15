resource "azurerm_linux_virtual_machine_scale_set" "agents" {
  name                   = "vmss-devopsagents-demo-weu"
  resource_group_name    = data.azurerm_resource_group.main.name
  location               = data.azurerm_resource_group.main.location
  sku                    = "Standard_B2s"
  instances              = 1
  admin_username         = "adm_ubuntu"
  overprovision          = false
  upgrade_mode           = "Manual"
  single_placement_group = false

  admin_ssh_key {
    username   = "adm_ubuntu"
    public_key = file("${path.module}/ssh_keys/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-devopsagents-demo-weu"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.agents.id
    }
  }
}

resource "azurestack_virtual_machine_extension" "installations" {
  name                         = "DevopsAgent"
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.agents.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"

  settings = <<SETTINGS
    {
        "script": "${filebase64("custom_scripts/installation.sh")}"
    }
SETTINGS
}