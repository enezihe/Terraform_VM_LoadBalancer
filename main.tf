terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.49.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
     }
}

resource "azurerm_resource_group" "rg1" {
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.vnet_location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.60.0.0/22"]
  }

resource "azurerm_subnet" "subnet1" {
  name                 = var.subnet1_name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.0.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = var.subnet2_name
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.1.0/24"]
}

module "vm1" {
  source = "./module/vm_module"
  vm_name = "vm1"
  resource_group_name = azurerm_resource_group.rg1.name
  username = "nbt00"
  password = "Password1234"
  subnet_id = azurerm_subnet.subnet1.id
}

module "vm2" {
  source = "./module/vm_module"
  vm_name = "vm2"
  resource_group_name = azurerm_resource_group.rg1.name
  username = "nbt00"
  password = "Password1234"
  subnet_id = azurerm_subnet.subnet2.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "acceptanceTestSecurityGroup1"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg1.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "ensg_subnet1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "ensg_subnet2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_resource_group" "rg2" {
  name     = var.rg2_name
  location = var.rg_location
}

resource "azurerm_public_ip" "pip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = var.rg_location
  allocation_method   = "Static"
  sku = "Standard"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_lb" "lb" {
  name                = "TestLoadBalancer"
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"
  

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backendlb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "probelb" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "http-running-probe"
  port            = 80
}
resource "azurerm_lb_rule" "rulelb" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.probelb.id
  backend_address_pool_ids=[ azurerm_lb_backend_address_pool.backendlb.id ]

}
resource "azurerm_network_interface_backend_address_pool_association" "bacend_assoc1" {
  network_interface_id    = module.vm1.nic_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendlb.id
}
resource "azurerm_network_interface_backend_address_pool_association" "bacend_assoc2" {
  network_interface_id    = module.vm2.nic_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backendlb.id
}

resource "azurerm_virtual_machine_extension" "vm1-extensions" {
  name                 = "vm01-ext-webserver"
  virtual_machine_id   = module.vm1.vm_id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server"
    }
SETTINGS

}
resource "azurerm_virtual_machine_extension" "vm2-extensions" {
  name                 = "vm01-ext-webserver"
  virtual_machine_id   = module.vm2.vm_id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature Web-Server"
    }
SETTINGS

}




