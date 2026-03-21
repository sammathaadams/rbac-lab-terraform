# Azure RBAC Access Control Lab

Azure RBAC role assignments on top of the Lab 1 infrastructure — scoped to the FS01 file server. Deployed with Terraform, validated automatically with PowerShell and Azure CLI.

> **Prerequisite:** [Lab 1 — NTFS File Server Lab](https://github.com/sammathaadams/ntfs-lab-terraform) must be deployed before running this lab. This repo does not create any VMs — it assigns roles to the infrastructure already running from Lab 1.

---

## What You'll Learn

- Understanding Azure RBAC vs NTFS permissions (two different layers of access control)
- Assigning built-in Azure roles (Owner, Virtual Machine Contributor, Reader)
- Scoping roles to a specific resource instead of the entire subscription or resource group
- Using Terraform data sources to reference existing infrastructure without recreating it
- Validating role assignments with Azure CLI
- Testing what each role can and cannot do on a real VM

---

## Architecture

Lab 2 adds RBAC role assignments **on top of** the existing Lab 1 infrastructure. The VMs, VNet, and Resource Group are not modified — only three role assignments are created, all scoped to the FS01 VM.

```
┌─────────────────────────────────────────────────────────────────────┐
│  Lab 1 Infrastructure (existing — ntfs-lab-terraform)               │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Azure VNet  10.0.0.0/16  │  Subnet: 10.0.1.0/24            │  │
│  │                                                               │  │
│  │   ┌─────────┐    ┌──────────────────┐    ┌─────────────┐    │  │
│  │   │  DC01   │    │      FS01        │    │  CLIENT01   │    │  │
│  │   │ (AD DS) │◄───│  (File Server)   │◄───│ (Workstation│    │  │
│  │   └─────────┘    └────────┬─────────┘    └─────────────┘    │  │
│  │                           │  ← RBAC scope (Lab 2)            │  │
│  └───────────────────────────┼───────────────────────────────────┘  │
└──────────────────────────────┼──────────────────────────────────────┘
                               │
          ┌────────────────────┼──────────────────────┐
          │                   │                       │
   ┌──────┴──────┐   ┌────────┴────────┐   ┌─────────┴──────┐
   │  SysAdmin   │   │   SupportTech   │   │    Auditor     │
   │   Owner     │   │ VM Contributor  │   │    Reader      │
   │  (full IAM) │   │ (start/stop/RDP)│   │  (view only)   │
   └─────────────┘   └─────────────────┘   └────────────────┘
```

| Role | Start/Stop VM | Connect RDP | Delete VM | Manage RBAC |
|------|:---:|:---:|:---:|:---:|
| Owner (SysAdmin) | ✅ | ✅ | ✅ | ✅ |
| VM Contributor (SupportTech) | ✅ | ✅ | ❌ | ❌ |
| Reader (Auditor) | ❌ | ❌ | ❌ | ❌ |

> **Why FS01 scope?** Assigning roles at the VM level is least-privilege — the SupportTech can only manage FS01, not DC01, CLIENT01, or any other resource in the subscription.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Lab 1 deployed** | [ntfs-lab-terraform](https://github.com/sammathaadams/ntfs-lab-terraform) must be running |
| Terraform | >= 1.5.0 — [Download](https://developer.hashicorp.com/terraform/downloads) |
| Azure CLI | Latest — `winget install Microsoft.AzureCLI` |
| Azure AD users | Three users in your tenant to assign the lab roles to |

---

## Step 1 — Get Object IDs

Each role assignment needs the Azure AD **Object ID** of the user receiving it. Run the helper script to look them up:

```powershell
.\scripts\01-get-object-ids.ps1
```

The script prompts for three UPNs and prints the Object IDs ready to paste:

```
=== Paste these into terraform.tfvars ===
sysadmin_object_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
support_user_object_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
auditor_object_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

---

## Step 2 — Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and paste in the Object IDs from Step 1:

```hcl
resource_group_name    = "RG-FileServerLab"   # Must match your Lab 1 deployment
vm_name                = "FS01"
location               = "Central US"

sysadmin_object_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
support_user_object_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
auditor_object_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

> **Security Note:** `terraform.tfvars` is excluded from git via `.gitignore`. Object IDs are treated as sensitive — never commit them.

---

## Step 3 — Deploy RBAC Assignments

```bash
# Login to Azure
az login

# Initialise providers
terraform init

# Preview the three role assignments
terraform plan

# Apply (completes in under 1 minute)
terraform apply
```

After `terraform apply` completes, confirm the outputs:

```
Outputs:

resource_group_name = "RG-FileServerLab"
vm_name             = "FS01"
vm_id               = "/subscriptions/.../FS01"
subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
rbac_summary        = <sensitive>   ← use validate-lab.ps1 to display this
```

> **What gets deployed:** Three Azure role assignments scoped to FS01. No VMs, no networking, no resource group — Lab 1's infrastructure is untouched.

---

## Step 4 — Validate the Lab (Automated)

This single command confirms all three role assignments are in place, prints the permission matrix, and exports a lab report:

```powershell
.\validate-lab.ps1
```

The script runs through these stages automatically:

| Stage | What Happens |
|-------|-------------|
| 1 | Confirms Owner, VM Contributor, and Reader are assigned on FS01 |
| 2 | Prints the permission matrix and checks the current logged-in user's role |
| 3 | Exports `RBAC_Lab_Report.txt` with full assignment details and a checklist |

**Total time: under 30 seconds.**

A `[PASS]` / `[FAIL]` result prints for each expected role assignment.

---

## Step 5 — Test As Each User

Log in to Azure CLI as each persona to demonstrate what their role allows:

```bash
# Open a new terminal and log in as the user being tested
az login

# All roles — should succeed
az vm show -g RG-FileServerLab -n FS01

# Owner + VM Contributor only — Auditor should get "AuthorizationFailed"
az vm stop -g RG-FileServerLab -n FS01 --no-wait
az vm start -g RG-FileServerLab -n FS01

# Owner only — VM Contributor and Auditor should be denied
az role assignment list --scope <vm-id-from-terraform-output>
```

Use `scripts/03-test-permissions.ps1` as a reference guide during your walkthrough.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `terraform apply` fails — "principal not found" | Object ID is incorrect. Re-run `01-get-object-ids.ps1` to get fresh IDs |
| `terraform apply` fails — "resource group not found" | Lab 1 is not deployed. Deploy [ntfs-lab-terraform](https://github.com/sammathaadams/ntfs-lab-terraform) first |
| `validate-lab.ps1` fails — "VM not found" | Check `resource_group_name` and `vm_name` match your Lab 1 tfvars exactly |
| Role assignment shows but user still can't act | Azure RBAC can take up to 5 minutes to propagate — wait and retry |
| `az login` prompts even though already logged in | Run `az account show` to confirm the active session before running scripts |
| Object ID lookup returns empty | User may not exist in your tenant — check the UPN in Azure AD |

---

## Teardown

This lab only creates role assignments — it does **not** delete the Lab 1 VMs when destroyed.

```bash
# Remove the three RBAC role assignments only
terraform destroy
```

> The VMs, VNet, Resource Group, and Key Vault from Lab 1 remain intact. To tear down Lab 1 as well, run `az group delete -n RG-FileServerLab --yes` from the ntfs-lab-terraform repo.

---

## Project Structure

```
rbac-lab-terraform/
├── main.tf                        # Azure provider configuration
├── versions.tf                    # Provider version constraints
├── data.tf                        # References existing Lab 1 infrastructure
├── rbac.tf                        # Three RBAC role assignments on FS01
├── variables.tf                   # Input variable definitions
├── outputs.tf                     # Output values (VM ID, subscription, etc.)
├── terraform.tfvars.example       # Safe template — commit this
├── terraform.tfvars               # Your real values — DO NOT commit
├── .gitignore                     # Excludes tfvars, state, .terraform/
├── validate-lab.ps1               # One-shot validation (run after terraform apply)
└── scripts/
    ├── 01-get-object-ids.ps1      # Retrieves Azure AD Object IDs for tfvars
    ├── 02-validate-rbac.ps1       # Confirms role assignments are in place
    ├── 03-test-permissions.ps1    # Permission matrix + live role check
    └── 04-export-report.ps1       # Exports RBAC_Lab_Report.txt
```

---

## License

MIT
