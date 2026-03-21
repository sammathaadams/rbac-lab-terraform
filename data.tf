##############################################################################
# data.tf
# Purpose : Reference existing Lab 1 (NTFS File Server Lab) infrastructure
#
# All resources below already exist — Terraform reads them without modifying.
# The RBAC assignments in rbac.tf are scoped to the FS01 VM resource ID
# retrieved here.
##############################################################################

# ── Existing Resource Group (from Lab 1) ─────────────────────────────────────
# Lab 1 default: "RG-FileServerLab"
data "azurerm_resource_group" "lab_rg" {
  name = var.resource_group_name
}

# ── Existing FS01 Virtual Machine (from Lab 1) ────────────────────────────────
# The file server created in the NTFS lab — this is the RBAC target.
data "azurerm_virtual_machine" "fs01" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.lab_rg.name
}

# ── Current Subscription ─────────────────────────────────────────────────────
# Provides subscription ID for outputs and scope references.
data "azurerm_subscription" "current" {}

# ── Current Client Config ─────────────────────────────────────────────────────
# Provides the tenant_id of the account running Terraform.
data "azurerm_client_config" "current" {}
