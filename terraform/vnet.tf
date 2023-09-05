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
    count               = var.create_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.42.42.0/23"]
}

resource "azurerm_public_ip" "bastion" {
    count               = var.create_bastion ? 1 : 0
  name                = azurecaf_name.main.results["azurerm_public_ip"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}


resource "azurerm_network_security_group" "main" {
  location            = azurerm_resource_group.main.location
  name                = azurecaf_name.main.results["azurerm_network_security_group"]
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "AllowCidrBlockHTTPInbound"
    priority                   = 3000
    protocol                   = "Tcp"
    destination_address_prefix = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "${chomp(data.http.myip.response_body)}/32"
    source_port_range          = "*"
  }
}

# resource "azurerm_subnet_network_security_group_association" "main" {
#   network_security_group_id = azurerm_network_security_group.main.id
#   subnet_id                 = azurerm_subnet.main.id
# }
