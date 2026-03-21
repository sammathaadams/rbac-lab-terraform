##############################################################################
# 04-export-report.ps1
# Run from : YOUR LOCAL MACHINE (after validation)
# Purpose  : Generate a text lab report documenting RBAC assignments
#
# Output   : RBAC_Lab_Report.txt saved to your current directory
#
# Usage    : .\scripts\04-export-report.ps1
#            Called automatically by validate-lab.ps1
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in: az login
##############################################################################

param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$VMName        = "FS01",
    [string]$ReportPath    = ".\RBAC_Lab_Report.txt"
)

# -- Gather data via az CLI ---------------------------------------------------
$VMId        = az vm show -g $ResourceGroup -n $VMName --query id -o tsv --only-show-errors 2>$null
$powerState  = az vm show -g $ResourceGroup -n $VMName -d --query powerState -o tsv --only-show-errors 2>$null
$subName     = az account show --query name -o tsv
$subId       = az account show --query id -o tsv
$operator    = az account show --query user.name -o tsv
$timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$assignmentsJson = az role assignment list --scope $VMId --output json --only-show-errors
$assignments     = ($assignmentsJson -join "`n") | ConvertFrom-Json

# -- Build assignments section ------------------------------------------------
$assignmentLines = if ($assignments.Count -eq 0) {
    "  No assignments found at this scope."
} else {
    ($assignments | ForEach-Object {
        "  Role  : $($_.roleDefinitionName)`n  User  : $($_.principalName)`n  Scope : $($_.scope)`n  ---"
    }) -join "`n"
}

# -- Build report -------------------------------------------------------------
$report = @"
==============================================================================
  AZURE RBAC LAB REPORT
  Lab     : Azure RBAC Access Control (Lab 2)
  Target  : FS01 Virtual Machine
  Generated : $timestamp
  Operator  : $operator
==============================================================================

SUBSCRIPTION   : $subName ($subId)
RESOURCE GROUP : $ResourceGroup
VIRTUAL MACHINE: $VMName
VM STATE       : $powerState
VM RESOURCE ID : $VMId

------------------------------------------------------------------------------
RBAC ROLE ASSIGNMENTS (VM Scope)
------------------------------------------------------------------------------
$assignmentLines

------------------------------------------------------------------------------
VALIDATION CHECKLIST
------------------------------------------------------------------------------
  [ ] Owner assigned to SysAdmin
  [ ] Virtual Machine Contributor assigned to SupportTech
  [ ] Reader assigned to Auditor
  [ ] Least privilege enforced (roles scoped to VM, not entire RG)
  [ ] Unauthorized actions blocked (tested via 03-test-permissions.ps1)
  [ ] terraform apply completed without errors

------------------------------------------------------------------------------
ROLE PERMISSION SUMMARY
------------------------------------------------------------------------------
  Role                       Start/Stop   Delete VM   Manage RBAC
  -------------------------  -----------  ----------  -----------
  Owner (SysAdmin)           YES          YES         YES
  VM Contributor (Support)   YES          NO          NO
  Reader (Auditor)           NO           NO          NO

------------------------------------------------------------------------------
NOTES / OBSERVATIONS
------------------------------------------------------------------------------
  (Add your test results and screenshot references here)




==============================================================================
END OF REPORT
==============================================================================
"@

# -- Write to file ------------------------------------------------------------
$report | Out-File -FilePath $ReportPath -Encoding utf8
Write-Host "`nReport saved to: $(Resolve-Path $ReportPath)" -ForegroundColor Green
Write-Host "Open it and fill in the checklist before submitting your lab." -ForegroundColor Yellow
