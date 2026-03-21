##############################################################################
# 03-test-permissions.ps1
# Run from : YOUR LOCAL MACHINE (after terraform apply)
# Purpose  : Verify what each lab role can and cannot do on FS01
#            Uses az CLI to check effective permissions
#
# Usage    : .\scripts\03-test-permissions.ps1
#            Called automatically by validate-lab.ps1
#
# HOW THIS WORKS:
#   "az role assignment list" shows us what roles are assigned.
#   We cross-reference against the known permission matrix for each role.
#   For a true test, log in as each user and run "az vm show / stop / start"
#   -- the table below documents what you should expect.
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in: az login
##############################################################################

param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$VMName        = "FS01"
)

Write-Host "`n=== Role Permission Matrix for FS01 ===" -ForegroundColor Cyan

# -- Get assignments ----------------------------------------------------------
$VMId = az vm show -g $ResourceGroup -n $VMName --query id -o tsv --only-show-errors 2>$null
$assignmentsJson = az role assignment list --scope $VMId --output json --only-show-errors
$assignments = ($assignmentsJson -join "`n") | ConvertFrom-Json

# -- Print permission matrix --------------------------------------------------
Write-Host @"

  Action                          Owner   VM Contributor   Reader
  ------------------------------  ------  ---------------  ------
  View VM config / metrics        YES     YES              YES
  Start VM                        YES     YES              NO
  Stop VM                         YES     YES              NO
  Restart VM                      YES     YES              NO
  Connect via RDP (port 3389)     YES     YES              NO
  Delete VM                       YES     NO               NO
  Manage RBAC assignments         YES     NO               NO

"@ -ForegroundColor White

# -- Show who holds each role -------------------------------------------------
Write-Host "=== Assigned Personas ===" -ForegroundColor Cyan

foreach ($role in @("Owner", "Virtual Machine Contributor", "Reader")) {
    $match = $assignments | Where-Object { $_.roleDefinitionName -eq $role }
    if ($match) {
        Write-Host "  $($role.PadRight(30)) -> $($match.principalName)" -ForegroundColor Green
    } else {
        Write-Host "  $($role.PadRight(30)) -> NOT ASSIGNED" -ForegroundColor Red
    }
}

# -- Live permission check for the current logged-in user ---------------------
Write-Host "`n=== Current User Permission Check ===" -ForegroundColor Cyan
$currentUser = az account show --query user.name -o tsv

Write-Host "  Logged in as: $currentUser" -ForegroundColor White

$myAssignment = $assignments | Where-Object { $_.principalName -eq $currentUser }
if ($myAssignment) {
    Write-Host "  Your role on $VMName : $($myAssignment.roleDefinitionName)" -ForegroundColor Green
} else {
    Write-Host "  You have no direct role assignment at the VM scope." -ForegroundColor Yellow
    Write-Host "  (You may have access via a broader scope e.g. subscription Owner)" -ForegroundColor DarkGray
}

# -- Verify VM is reachable ---------------------------------------------------
Write-Host "`n=== VM State ===" -ForegroundColor Cyan
$powerState = az vm show -g $ResourceGroup -n $VMName -d --query powerState -o tsv --only-show-errors
Write-Host "  $VMName power state: $powerState" -ForegroundColor White

Write-Host "`n=== To Test As Each User ===" -ForegroundColor Yellow
Write-Host "  1. Open a NEW terminal and run: az login"
Write-Host "  2. Sign in as the user you want to test (SysAdmin, SupportTech, or Auditor)"
Write-Host "  3. Try: az vm show -g $ResourceGroup -n $VMName    (should work for all roles)"
Write-Host "  4. Try: az vm stop -g $ResourceGroup -n $VMName    (Owner + SupportTech only)"
Write-Host "  5. Try: az role assignment list --scope <VM-ID>    (Owner only)"
