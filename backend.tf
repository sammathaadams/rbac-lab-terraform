##############################################################################
# backend.tf
#
# Purpose: Store Terraform state remotely in Azure Blob Storage instead of
#          on your local machine. This is required enterprise practice because
#          terraform.tfstate contains sensitive values in plaintext.
#
# IMPORTANT — use the SAME storage account created during Lab 1 pre-setup.
# The state for this lab is stored under a different key (rbac-lab) so the
# two labs never overwrite each other's state.
#
# After completing Lab 1 pre-setup, replace the placeholder below with your
# storage account name, then run: terraform init
##############################################################################

terraform {
  backend "azurerm" {
    resource_group_name  = "RG-TerraformState"
    storage_account_name = "tfstatentfslab"
    container_name       = "tfstate"
    key                  = "rbac-lab.terraform.tfstate"
  }
}
