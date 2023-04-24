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
}


# resource "azurerm_policy_definition" "tagging_policy" {
#   name         = "tagging-policy"
#   display_name = "Tagging Policy"
#   description  = "Enforce tagging policy on resources"
#   policy_type  = "Custom"
#   mode         = "Indexed"

#   metadata = <<METADATA
#     {
#       "category": "Tags",
#       "version": "1.0.0"
#     }
#   METADATA

#   policy_rule = <<POLICYRULE
#     {
#       "if": {
#       "anyOf": [
#         {
#           "field": "tags",
#           "exists": "false"
#         },
#         {
#           "field": "tags",
#           "equals": ""
#         },
#         {
#           "field": "tags",
#           "equals": "{}"
#         }
#       ]
#       },
#       "then": {
#         "effect": "deny"
#       }
#     }
#   POLICYRULE
#   # parameters           = <<PARAMETERS
#   #   {
#   #    "tagName": {
#   #       "type": "String",
#   #       "value": "Project",
#   #       "metadata": {
#   #           "description": "Name of the tag, such as costCenter"
#   #       }
#   #     },
#   #     "tagValue": {
#   #       "type": "String",
#   #       "value": "Course1-Udacity",
#   #       "metadata": {
#   #           "description": "Value of the tag, such as headquarter"
#   #       }
#   #     }
#   #   }
#   # PARAMETERS
# }
# resource "azurerm_subscription_policy_assignment" "tagging_policy_assignment" {
#   name                 = "tagging-policy-assignment"
#   display_name         = "Tagging Policy Assignment"
#   policy_definition_id = azurerm_policy_definition.tagging_policy.id
#   subscription_id      = "/subscriptions/${var.subscription_id}"
#   description          = "Enforce tagging policy on subscription"
#   # parameters           = <<PARAMETERS
#   #   {
#   #     "tagName": {
#   #       "value": "Project"
#   #     },
#   #     "tagValue": {
#   #       "value": "Course1-Udacity"
#   #     }
#   #   }
#   # PARAMETERS
# }

#trigger the policy scan
# resource "null_resource" "trigger_policy_compliance_scan" {
#   provisioner "local-exec" {
#     command = "az rest --method post --uri https://management.azure.com/subscriptions/${var.subscription_id}/resourceGroups/${var.prefix}/providers/Microsoft.PolicyInsights/policyStates/latest/triggerEvaluation?api-version=2019-10-01"
#   }

#   depends_on = [azurerm_resource_group.main]
# }
# resource "null_resource" "example" {
#   provisioner "local-exec" {
#     # command = "az policy state trigger-scan --policy-assignment ${azurerm_subscription_policy_assignment.tagging_policy_assignment.id}"
#     command = "az policy state trigger-scan --resource-group ${azurerm_resource_group.main.name}"
#   }
# }

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  #resize VNet
  address_space       = ["${var.address_space}"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

#add NSG definition

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

#   security_rule {
#     name                       = "allow-rdp"
#     priority                   = 200
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "allow-ssh"
#     priority                   = 220
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

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
  #   security_rule {
  #   name                       = "allow-access-lb"
  #   priority                   = 240
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   source_address_prefix      = "*"
  #   # destination_address_prefix  = azurerm_lb.main.frontend_ip_configuration.0.public_ip_address_id
  #   destination_address_prefix  = azurerm_public_ip.main.id
  #   destination_port_range     = "*"
    
  # }
}


resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["${var.subnet_space}"]
  # network_security_group_id = azurerm_network_security_group.nsg.id
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

  tags = {
    environment = "Test"
  }
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
    # public_ip_address_id = azurerm_public_ip.main.id
  }
}

#add VMAS

 resource "azurerm_availability_set" "myVmas" {
   name                         = "${var.prefix}-myVmas"
   resource_group_name          = azurerm_resource_group.main.name
   location                     = azurerm_resource_group.main.location
   platform_fault_domain_count  = "${var.faultDomain}"
   platform_update_domain_count = "${var.updateDomain}"
   managed                      = true
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
  # network_interface_ids = [
  #   azurerm_network_interface.main.id,
  # ]
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]

  source_image_id = data.azurerm_image.myImage.id
  # source_image_reference {
  #   # publisher = "Canonical"
  #   # offer     = "UbuntuServer"
  #   # sku       = "18.04-LTS"
  #   # version   = "latest"
  #   source_image_id = data.azurerm_image.myImage.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  # tags        = {
  # project = "course1-NghiLe"
  # }

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
 }

#add Managed Disk Attachment
resource "azurerm_virtual_machine_data_disk_attachment" "diskattach" {
  count              = "${var.numberOfVMs}"
  managed_disk_id    = element(azurerm_managed_disk.managedDisk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                = "1"
  caching            = "ReadWrite"
}

