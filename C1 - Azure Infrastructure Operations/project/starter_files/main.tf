 terraform {

   required_version = ">=1.0"

   required_providers {
     azurerm = {
       source = "hashicorp/azurerm"
       version = ">=3.0"
     }
   }
 }

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}"
  location = var.location

  tags = var.tags
}


resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["${var.address_space}"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

   tags = var.tags
}

#add NSG definition
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name



    security_rule {
    name                       = "allow-internal-communication"
    priority                   = 230
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.internal.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }
  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 240
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes[0]
  }

   tags = var.tags
}


resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["${var.subnet_space}"]
}

# add NSG association
resource "azurerm_subnet_network_security_group_association" "sample" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.nsg.id


}

resource "azurerm_public_ip" "main" {
  name                = "publicIpForLB"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

   tags = var.tags
}

#add LB definition
 resource "azurerm_lb" "main" {
   name                = "${var.prefix}-loadBalancer"
   location            = azurerm_resource_group.main.location
   resource_group_name = azurerm_resource_group.main.name

   frontend_ip_configuration {
     name                 = "publicIPAddress"
     public_ip_address_id = azurerm_public_ip.main.id
   }
   tags = var.tags
 }

#add BE pool
 resource "azurerm_lb_backend_address_pool" "main" {
   loadbalancer_id     = azurerm_lb.main.id
   name                = "${var.prefix}-BackEndAddressPool"

 }

resource "azurerm_network_interface" "main" {
  count              = "${var.numberOfVMs}"
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

   tags = var.tags
}

#add VMAS

 resource "azurerm_availability_set" "myVmas" {
   name                         = "${var.prefix}-myVmas"
   resource_group_name          = azurerm_resource_group.main.name
   location                     = azurerm_resource_group.main.location
   platform_fault_domain_count  = "${var.faultDomain}"
   platform_update_domain_count = "${var.updateDomain}"
   managed                      = true

   tags = var.tags
 }

#add Azure Image from Packer 
data "azurerm_image" "myImage" {
  name                = "${var.packerImage}"
  resource_group_name = "${var.packerImageResouceGroup}"
}

#add VMAS ref, modified the image ref
resource "azurerm_linux_virtual_machine" "main" {
  count                           = "${var.numberOfVMs}"
  name                            = "${var.prefix}-vm${count.index}"
  availability_set_id             = azurerm_availability_set.myVmas.id
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  # size                            = "Standard_D2s_v3"
  size                            = "Standard_B1s"
  admin_username                  = "${var.username}"
  admin_password                  = "${var.password}"
  disable_password_authentication = false
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]

  source_image_id = data.azurerm_image.myImage.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

   tags = var.tags
}

#add Managed Disk
 resource "azurerm_managed_disk" "managedDisk" {
   count                = "${var.numberOfVMs}"
   name                 = "${var.prefix}-datadisk_${count.index}"
   location             = azurerm_resource_group.main.location
   resource_group_name  = azurerm_resource_group.main.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = 10

   tags = var.tags
 }

#add Managed Disk Attachment
resource "azurerm_virtual_machine_data_disk_attachment" "diskattach" {
  count              = "${var.numberOfVMs}"
  managed_disk_id    = element(azurerm_managed_disk.managedDisk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                = "1"
  caching            = "ReadWrite"

}

