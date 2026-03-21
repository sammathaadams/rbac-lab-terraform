##############################################################################
# 02-validate-rbac.ps1
# Run from : YOUR LOCAL MACHINE (after terraform apply)
# Purpose  : Confirm all three RBAC role assignments are in place on FS01
#
# Usage    : .\scripts\02-validate-rbac.ps1
#            Called automatically by validate-lab.ps1
#
# Prerequisites:
#   - Azure CLI installed
#   - Logged in: az login
##############################################################################

param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$VMName        = "FS01"
)

Write-Host "`n=== RBAC Assignment Validation ===" -ForegroundColor Cyan

# -- Get the VM resource ID ---------------------------------------------------
$VMId = az vm show -g $ResourceGroup -n $VMName --query id -o tsv --only-show-errors 2>$null

if (-not $VMId -or $LASTEXITCODE -ne 0) {
    Write-Error "VM '$VMName' not found in '$ResourceGroup'. Check names match your Lab 1 deployment."
    exit 1
}

Write-Host "  Target VM : $VMName" -ForegroundColor White
Write-Host "  Scope     : $VMId"   -ForegroundColor DarkGray

# -- Get all role assignments scoped to FS01 ----------------------------------
$assignmentsJson = az role assignment list --scope $VMId --output json --only-show-errors
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to retrieve role assignments. Ensure az login is active."
    exit 1
}

$assignments = ($assignmentsJson -join "`n") | ConvertFrom-Json

Write-Host "`n  Current assignments at VM scope:" -ForegroundColor White
if ($assignments.Count -eq 0) {
    Write-Warning "  No role assignments found. Check that terraform apply completed successfully."
} else {
    $assignments | ForEach-Object {
        Write-Host "    $($_.roleDefinitionName) -> $($_.principalName)" -ForegroundColor DarkGray
    }
}

# -- Check each expected role -------------------------------------------------
Write-Host "`n=== Validation Checks ===" -ForegroundColor Cyan
$pass = $true

$expectedRoles = @("Owner", "Virtual Machine Contributor", "Reader")

foreach ($role in $expectedRoles) {
    $match = $assignments | Where-Object { $_.roleDefinitionName -eq $role }
    if ($match) {
        Write-Host "  [PASS] '$role' assigned to: $($match.principalName)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] '$role' not found -- re-run terraform apply." -ForegroundColor Red
        $pass = $false
    }
}

if ($pass) {
    Write-Host "`n  All role assignments verified." -ForegroundColor Green
}

return $pass
