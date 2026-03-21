##############################################################################
# variables.tf
# Purpose : Input variable definitions for the RBAC lab
#
# Defaults match the Lab 1 (NTFS File Server Lab) naming exactly.
# Sensitive values (Object IDs) must be set in terraform.tfvars
# which is excluded from git via .gitignore.
##############################################################################

# -- Lab 1 Infrastructure -----------------------------------------------------

variable "resource_group_name" {
  description = "Name of the existing Lab 1 Resource Group."
  type        = string
  default     = "RG-FileServerLab"
}

variable "vm_name" {
  description = "Name of the existing FS01 Virtual Machine from Lab 1."
  type        = string
  default     = "FS01"
}

variable "location" {
  description = "Azure region where Lab 1 resources are deployed."
  type        = string
  default     = "Central US"
}

# -- RBAC Principal Object IDs ------------------------------------------------
# Set these in terraform.tfvars -- never hard-code here.
# To find an Object ID:  az ad user show --id "user@domain.com" --query id -o tsv

variable "sysadmin_object_id" {
  description = "Azure AD Object ID of the SysAdmin user. Receives Owner role on FS01."
  type        = string
  sensitive   = true
}

variable "support_user_object_id" {
  description = "Azure AD Object ID of the SupportTech user. Receives Virtual Machine Contributor role on FS01."
  type        = string
  sensitive   = true
}

variable "auditor_object_id" {
  description = "Azure AD Object ID of the Auditor user. Receives Reader role on FS01."
  type        = string
  sensitive   = true
}
