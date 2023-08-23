resource "azurecaf_name" "main" {
  name = var.azure_resource_base_name
  resource_types = [
    "azurerm_resource_group",
    "azurerm_application_insights",
    "azurerm_log_analytics_workspace",
    # "azurerm_private_endpoint",
    "azurerm_virtual_network",
    "azurerm_subnet",
    "azurerm_bastion_host",
    "azurerm_public_ip",
    # "azurerm_virtual_machine",
    "azurerm_network_interface",
    "azurerm_linux_virtual_machine"
  ]
  prefixes      = ["spc"]
  suffixes      = ["dev"]
  random_length = 5
  clean_input   = true
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.main.results["azurerm_resource_group"]
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = azurecaf_name.main.results["azurerm_virtual_network"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.42.40.0/22"]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet_main" {
  name                 = azurecaf_name.main.results["azurerm_subnet"]
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.42.40.0/23"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.42.42.0/23"]
}

resource "azurerm_public_ip" "bastion" {
  name                = azurecaf_name.main.results["azurerm_public_ip"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  name                = azurecaf_name.main.results["azurerm_bastion_host"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # file_copy_enabled  = true -- this is for standard sku
  sku                = "Basic"
  copy_paste_enabled = true

  ip_configuration {
    name                 = "BastionHostConfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_application_insights" "main" {
  name                = azurecaf_name.main.results["azurerm_application_insights"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = azurecaf_name.main.results["azurerm_log_analytics_workspace"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  tags                = var.tags
}


resource "azurerm_network_interface" "main" {
  name                = azurecaf_name.main.results["azurerm_network_interface"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                  = azurecaf_name.main.results["azurerm_linux_virtual_machine"]
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = "Standard_D2_v3"
  network_interface_ids = [azurerm_network_interface.main.id]
  admin_username        = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = data.cloudinit_config.main.rendered

}


data "cloudinit_config" "main" {
  #   gzip          = false
  #   base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/../app/cloud-init.yml.tftpl", { ai_key = "${azurerm_application_insights.main.connection_string}"})
  }

  part {
    filename     = "sendAIEvent.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/../app/sendAIEvent.sh")
  }

}

# resource "azurerm_private_endpoint" "app_insights_private_endpoint" {
#   name                = azurecaf_name.main.results["azurerm_private_endpoint"]
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   subnet_id           = azurerm_subnet.subnet_main.id

#   private_service_connection {
#     name                           = azurecaf_name.main.results["azurerm_private_endpoint"]
#     private_connection_resource_id = azurerm_application_insights.main.id
#     is_manual_connection           = false
#   }
#   tags = var.tags
# }

# resource "azurerm_private_endpoint" "log_analytics_private_endpoint" {
#   name                = azurecaf_name.main.results["azurerm_private_endpoint"]
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   subnet_id           = azurerm_subnet.subnet_main.id

#   private_service_connection {
#     name                           = azurecaf_name.main.results["azurerm_private_endpoint"]
#     private_connection_resource_id = azurerm_log_analytics_workspace.main.id
#     is_manual_connection           = false
#   }
#   tags = var.tags
# }

output "application_insights_instrumentation_key" {
  sensitive = true
  value     = azurerm_application_insights.main.connection_string
}

output "resource_group_name" {
    value = azurerm_resource_group.main.name
}
