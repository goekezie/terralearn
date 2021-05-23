provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  description = "The name used to identify the resource group"
  default = "learn-40123826-446f-408d-8492-54798031c1c6"
}

# variable "resource_group_location" {
#   description = "The name used to identify the location of the resource group"
#   default = ""
# }
variable "shared_key" {
  description = "The key used to create vpn connection"
  default = "Admin1234567"
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

output "id" {
  value = data.azurerm_resource_group.rg.id
}

resource "azurerm_virtual_network" "az" {
  name                = "Azure-VNet-1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "az" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.az.name
  address_prefixes     = ["10.0.255.0/27"]
}

resource "azurerm_public_ip" "az" {
  name                = "PIP-VNG-Azure-VNet-1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"

}

# resource "azurerm_virtual_network" "az" {
#   name                = "VNG-Azure-VNet-1"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   address_space       = ["10.0.255.0/27"]
# }

resource "azurerm_virtual_network_gateway" "az" {
  name                = "VNG-Azure-VNet-1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.az.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.az.id
  }
}

data "azurerm_public_ip" "az" {
  name                = azurerm_public_ip.az.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.az.ip_address
}

resource "azurerm_local_network_gateway" "az" {
  name                = "LNG-HQ-Network"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  gateway_address     = data.azurerm_public_ip.az.ip_address
  address_space       = ["172.17.0.0/16"]
}

resource "azurerm_virtual_network_gateway_connection" "az" {
  name                = "Azure-VNet-1-To-HQ-Network"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.az.id
  local_network_gateway_id   = azurerm_local_network_gateway.on.id

  shared_key = var.shared_key
}

# ------------------------------
resource "azurerm_virtual_network" "on" {
  name                = "HQ-Network"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = ["172.16.0.0/16"]
}
resource "azurerm_subnet" "on" {
  name                 = "GatewaySubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.on.name
  address_prefixes     = ["172.16.255.0/27"]
}

resource "azurerm_public_ip" "on" {
  name                = "PIP-VNG-HQ-Network"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"

}

# resource "azurerm_virtual_network" "az" {
#   name                = "VNG-Azure-VNet-1"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   address_space       = ["10.0.255.0/27"]
# }

resource "azurerm_virtual_network_gateway" "on" {
  name                = "VNG-HQ-Network"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.on.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.on.id
  }
}

data "azurerm_public_ip" "on" {
  name                = azurerm_public_ip.on.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

output "on_public_ip_address" {
  value = data.azurerm_public_ip.on.ip_address
}

resource "azurerm_local_network_gateway" "on" {
  name                = "LNG-Azure-VNet-1"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  gateway_address     = data.azurerm_public_ip.on.ip_address
  address_space       = ["172.16.255.0/27"]
}

resource "azurerm_virtual_network_gateway_connection" "on" {
  name                = "HQ-Network-To-Azure-VNet-1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.on.id
  local_network_gateway_id   = azurerm_local_network_gateway.az.id

  shared_key = var.shared_key
}
