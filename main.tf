##############################################################################
# main.tf
# Purpose : Azure provider configuration for the RBAC lab
#
# NOTE: The Resource Group and all VMs (DC01, FS01, CLIENT01) were created
#       in Lab 1 (ntfs-lab-terraform). This lab does NOT recreate them.
#       All existing infrastructure is referenced via data sources in data.tf.
#
# Prerequisites:
#   - Az CLI installed and logged in: az login
#   - Lab 1 terraform apply already completed
##############################################################################

provider "azurerm" {
  features {}
}
