##############################################################################
# validate-lab.ps1
# Purpose : One-shot RBAC lab validation -- runs from YOUR LOCAL MACHINE
#           after terraform apply completes
#
# Method  : Uses az CLI to query Azure directly - no VM access needed,
#           no WinRM, no RDP.
#
# Usage   : .\validate-lab.ps1
#           (uses defaults matching Lab 1 naming)
#
# Steps   :
#   1. Validate RBAC assignments are in place on FS01
#   2. Print the permission matrix and live role check
#   3. Export a lab report to RBAC_Lab_Report.txt
#
# Prerequisites:
#   - Azure CLI installed: winget install Microsoft.AzureCLI
#   - Logged in: az login
#   - terraform apply already completed
##############################################################################

param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$VMName        = "FS01"
)

$startTime = Get-Date

# -- Verify az CLI is logged in -----------------------------------------------
$account = az account show --query name -o tsv 2>$null
if (-not $account -or $LASTEXITCODE -ne 0) {
    throw "Not logged into Azure CLI. Run 'az login' first."
}
Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Logged in to Azure -- subscription: $account" -ForegroundColor Green

# ============================================================================
# STEP 1 -- Validate RBAC assignments
# ============================================================================
Write-Host "`n[STEP 1] Validating RBAC assignments on $VMName..." -ForegroundColor Magenta

& ".\scripts\02-validate-rbac.ps1" -ResourceGroup $ResourceGroup -VMName $VMName

if ($LASTEXITCODE -ne 0) {
    throw "RBAC validation failed. Check that terraform apply completed successfully."
}

# ============================================================================
# STEP 2 -- Test role permissions
# ============================================================================
Write-Host "`n[STEP 2] Checking role permission matrix..." -ForegroundColor Magenta

& ".\scripts\03-test-permissions.ps1" -ResourceGroup $ResourceGroup -VMName $VMName

# ============================================================================
# STEP 3 -- Export lab report
# ============================================================================
Write-Host "`n[STEP 3] Exporting lab report..." -ForegroundColor Magenta

& ".\scripts\04-export-report.ps1" -ResourceGroup $ResourceGroup -VMName $VMName

# ============================================================================
$duration = (Get-Date) - $startTime
Write-Host "`n=== Lab 2 Validation Complete ($([math]::Round($duration.TotalSeconds, 0))s) ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open RBAC_Lab_Report.txt and fill in the checklist"
Write-Host "  2. Log in as each user and run: az vm show / stop / start"
Write-Host "     to demonstrate what each role can and cannot do"
Write-Host "  3. Use script 03-test-permissions.ps1 as your test guide`n"
