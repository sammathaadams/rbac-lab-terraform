##############################################################################
# outputs.tf
# Purpose : Display useful information after terraform apply
#           Use these to confirm the correct resources were targeted
##############################################################################

output "resource_group_name" {
  description = "Resource Group containing FS01."
  value       = data.azurerm_resource_group.lab_rg.name
}

output "vm_name" {
  description = "Name of the target VM."
  value       = data.azurerm_virtual_machine.fs01.name
}

output "vm_id" {
  description = "Full Azure Resource ID of FS01 — this is the RBAC scope for all three role assignments."
  value       = data.azurerm_virtual_machine.fs01.id
}

output "subscription_id" {
  description = "Azure Subscription ID in use."
  value       = data.azurerm_subscription.current.subscription_id
}

output "tenant_id" {
  description = "Azure Tenant (Directory) ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "rbac_summary" {
  description = "Summary of RBAC roles assigned to FS01."
  value = {
    sysadmin     = "Owner -> ${var.sysadmin_object_id}"
    support_tech = "Virtual Machine Contributor -> ${var.support_user_object_id}"
    auditor      = "Reader -> ${var.auditor_object_id}"
  }
  sensitive = true
}
