variable "prefix" {
  description = "The prefix which should be used for all resources in this project"
  default = "nghile-course1"
}

variable "location" {
  description = "The Azure Region in which all resources in this project should be created."
  default = "eastus"
}

variable "username" {
  description = "The username of VMs"
  default = "testadmin"
}

variable "password" {
  description = "The password for VMs"
  default = "Password1234!"
}

variable "subnet_space" {
  description = "Insert the subnet of this VNet"
  default = "10.0.2.0/24"
}

variable "address_space" {
  description = "Insert the address_space of this VNet"
  default = "10.0.0.0/16"
}

variable "numberOfVMs" {
  description = "Number of VMs in this VMAS"
  default = 2
}

variable "faultDomain" {
  description = "Number of Fault Domain in this VMAS"
  default = 2
}

variable "updateDomain" {
  description = "Number of Update Domain in this VMAS"
  default = 2
}

variable "diskSizeGb" {
  description = "Managed Disk Size in GB for each VM"
  default = 10
}

variable "packerImage" {
  description = "Image you use to build VMs"
  default = "myImage"
}

variable "packerImageResouceGroup" {
  description = "The resouce group name which stores packer Image"
  default = "AzureDevOps_NghiLe"
}


variable "subscription_id" {
  description = "The subscription ID of your Azure Account"
  default = "123456"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Env = "Test"
    Owner       = "Nghi Le"
  }
}

variable "app_port" {
  description = "The port for the LB front end and back end"
  default = 80
}