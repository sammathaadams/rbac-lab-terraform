##############################################################################
# 01-get-object-ids.ps1
# Run from : YOUR LOCAL MACHINE (before filling terraform.tfvars)
# Purpose  : Retrieve Azure AD Object IDs for the three lab users
#            Run this ONCE before terraform apply
#
# Usage    : .\scripts\01-get-object-ids.ps1
#            (prompts for UPNs interactively)
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in: az login
##############################################################################

param(
    [string]$SysAdminUPN = "",   # e.g. sysadmin@yourdomain.com
    [string]$SupportUPN  = "",   # e.g. support@yourdomain.com
    [string]$AuditorUPN  = ""    # e.g. auditor@yourdomain.com
)

# If UPNs not passed as params, prompt interactively
if (-not $SysAdminUPN) { $SysAdminUPN = Read-Host "Enter SysAdmin UPN    (e.g. user@domain.com)" }
if (-not $SupportUPN)  { $SupportUPN  = Read-Host "Enter SupportTech UPN (e.g. user@domain.com)" }
if (-not $AuditorUPN)  { $AuditorUPN  = Read-Host "Enter Auditor UPN     (e.g. user@domain.com)" }

Write-Host "`n=== Retrieving Azure AD Object IDs ===" -ForegroundColor Cyan

$SysAdminId = az ad user show --id $SysAdminUPN --query id -o tsv 2>$null
$SupportId  = az ad user show --id $SupportUPN  --query id -o tsv 2>$null
$AuditorId  = az ad user show --id $AuditorUPN  --query id -o tsv 2>$null

if (-not $SysAdminId) { Write-Warning "Could not find user: $SysAdminUPN -- check the UPN and try again." }
if (-not $SupportId)  { Write-Warning "Could not find user: $SupportUPN -- check the UPN and try again."  }
if (-not $AuditorId)  { Write-Warning "Could not find user: $AuditorUPN -- check the UPN and try again."  }

Write-Host "`n  SysAdmin    : $SysAdminUPN -> $SysAdminId" -ForegroundColor Green
Write-Host "  SupportTech : $SupportUPN  -> $SupportId"  -ForegroundColor Green
Write-Host "  Auditor     : $AuditorUPN  -> $AuditorId"  -ForegroundColor Green

Write-Host "`n=== Paste these into terraform.tfvars ===" -ForegroundColor Yellow
Write-Host "sysadmin_object_id     = `"$SysAdminId`""
Write-Host "support_user_object_id = `"$SupportId`""
Write-Host "auditor_object_id      = `"$AuditorId`""
