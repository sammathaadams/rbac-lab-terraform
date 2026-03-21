##############################################################################
# rbac.tf
# Purpose : Assign Azure RBAC roles to three lab personas on FS01
#
# Scope   : FS01 VM only (least-privilege — not the whole resource group)
#
# Roles assigned:
#   SysAdmin    -> Owner                       (full control)
#   SupportTech -> Virtual Machine Contributor (start/stop/restart, no delete)
#   Auditor     -> Reader                      (view only, no changes)
#
# How to find Object IDs:
#   az ad user show --id "user@domain.com" --query id -o tsv
#   Or run: scripts/01-get-object-ids.ps1
##############################################################################

# -- Role 1: SysAdmin -> Owner ------------------------------------------------
resource "azurerm_role_assignment" "sysadmin_owner" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Owner"
  principal_id         = var.sysadmin_object_id
}

# -- Role 2: SupportTech -> Virtual Machine Contributor -----------------------
# Start / Stop / Restart VM, Connect via RDP
# Cannot: Delete VM or modify RBAC assignments
resource "azurerm_role_assignment" "supporttech_vm_contributor" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.support_user_object_id
}

# -- Role 3: Auditor -> Reader ------------------------------------------------
# View VM config and metrics only — cannot start, stop, or make changes
resource "azurerm_role_assignment" "auditor_reader" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Reader"
  principal_id         = var.auditor_object_id
}

##############################################################################
# OPTIONAL: Broader scope at the Resource Group level
# Uncomment to apply roles to ALL resources in RG-FileServerLab instead of FS01 only.
#
# resource "azurerm_role_assignment" "sysadmin_rg_owner" {
#   scope                = data.azurerm_resource_group.lab_rg.id
#   role_definition_name = "Owner"
#   principal_id         = var.sysadmin_object_id
# }
##############################################################################
