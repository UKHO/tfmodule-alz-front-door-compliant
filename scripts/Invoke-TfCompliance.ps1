#Requires -Version 7.4
<#
.SYNOPSIS
    Runs terraform-compliance BDD policy tests for both Front Door modules.
.DESCRIPTION
    For each module (front-door-platform and front-door-delivery), generates a
    Terraform plan JSON using the module's compliance fixture, then runs
    terraform-compliance against each policy suite in that module.
    All suites across both modules run regardless of individual failures to surface
    all issues at once. Cleans up plan files on exit.
.PARAMETER SubscriptionId
    Azure subscription ID to use for plan generation. Required.
.PARAMETER RepoRoot
    Path to the root of the tfmodule-alz-front-door-compliant repository.
    Defaults to the parent of the scripts directory.
.PARAMETER PlanFile
    Name of the plan JSON file to generate per module. Defaults to 'tfplan.json'.
.EXAMPLE
    ./Invoke-TfCompliance.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000001"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [string]$RepoRoot = (Join-Path $PSScriptRoot ".."),

    [string]$PlanFile = "tfplan.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path $RepoRoot

$Modules = @(
    @{
        Name   = "front-door-platform"
        Suites = @("sku_enforcement", "enforce_guardrails_network", "tagging_requirements")
    },
    @{
        Name   = "front-door-delivery"
        Suites = @("https_enforcement", "tls_enforcement", "origin_security")
    }
)

# Locate terraform-compliance: prefer project .venv, fall back to system PATH
$VenvBin = Join-Path $RepoRoot ".venv" "Scripts" "terraform-compliance.exe"
if (Test-Path $VenvBin) {
    $TerraformComplianceBin = $VenvBin
}
else {
    $TerraformComplianceBin = "terraform-compliance"
}
Write-Host "    Using terraform-compliance: $TerraformComplianceBin" -ForegroundColor Gray

# Use Azure CLI credentials for plan generation
$env:ARM_USE_CLI = "true"

$failedSuites = @()
$passedSuites = @()

# Collect all plan file paths for cleanup
$allPlanBinaries  = @()
$allPlanJsonPaths = @()

foreach ($module in $Modules) {
    $FixtureDir        = Join-Path $RepoRoot "modules" $module.Name "compliance" "fixture"
    $allPlanBinaries  += Join-Path $FixtureDir "tfplan"
    $allPlanJsonPaths += Join-Path $FixtureDir $PlanFile
}

try {
    foreach ($module in $Modules) {
        $ModuleDir     = Join-Path $RepoRoot "modules" $module.Name
        $FixtureDir    = Join-Path $ModuleDir "compliance" "fixture"
        $ComplianceDir = Join-Path $ModuleDir "compliance"
        $VarFile       = Join-Path $ComplianceDir "compliance.tfvars"
        $PlanBinary    = Join-Path $FixtureDir "tfplan"
        $PlanJsonPath  = Join-Path $FixtureDir $PlanFile

        if (-not (Test-Path $VarFile)) {
            Write-Host "$($module.Name): FAIL (variables file not found: $VarFile)" -ForegroundColor Red
            $failedSuites += "$($module.Name)/varfile"
            continue
        }
        $VarFile = Resolve-Path $VarFile

        Write-Host ""
        Write-Host "=====================================================================" -ForegroundColor Cyan
        Write-Host "  Module: $($module.Name)" -ForegroundColor Cyan
        Write-Host "=====================================================================" -ForegroundColor Cyan

        # Remove stale .terraform/terraform.tfstate left by earlier init
        $DotTerraformState = Join-Path $FixtureDir ".terraform" "terraform.tfstate"
        Remove-Item -Path $DotTerraformState -ErrorAction SilentlyContinue

        # Step 1: Init
        Write-Host ""
        Write-Host "==> terraform init: $($module.Name)" -ForegroundColor Cyan
        terraform -chdir="$FixtureDir" init -reconfigure -input=false

        if ($LASTEXITCODE -ne 0) {
            Write-Host "$($module.Name): FAIL (terraform init failed)" -ForegroundColor Red
            $failedSuites += "$($module.Name)/init"
            continue
        }

        # Step 2: Generate plan binary
        Write-Host ""
        Write-Host "==> Generating compliance plan: $($module.Name)" -ForegroundColor Cyan
        terraform -chdir="$FixtureDir" plan `
            -var-file="$VarFile" `
            -var "subscription_id=$SubscriptionId" `
            -input=false `
            -out="$PlanBinary"

        if ($LASTEXITCODE -ne 0) {
            Write-Host "$($module.Name): FAIL (terraform plan failed)" -ForegroundColor Red
            $failedSuites += "$($module.Name)/plan"
            continue
        }

        # Step 3: Convert plan binary to JSON
        terraform -chdir="$FixtureDir" show -json "$PlanBinary" | Out-File -FilePath $PlanJsonPath -Encoding utf8

        if ($LASTEXITCODE -ne 0) {
            Write-Host "$($module.Name): FAIL (terraform show -json failed)" -ForegroundColor Red
            $failedSuites += "$($module.Name)/show"
            continue
        }

        Write-Host "    Plan JSON generated: $PlanJsonPath" -ForegroundColor Gray

        # Step 4: Run each compliance suite
        foreach ($suite in $module.Suites) {
            $suiteDir = Join-Path $ComplianceDir $suite

            if (-not (Test-Path $suiteDir)) {
                Write-Host "  [SKIP] Suite not found: $suite" -ForegroundColor Yellow
                continue
            }

            Write-Host ""
            Write-Host "==> terraform-compliance: $($module.Name)/$suite" -ForegroundColor Cyan

            & $TerraformComplianceBin -p $PlanJsonPath -f $suiteDir

            if ($LASTEXITCODE -ne 0) {
                $failedSuites += "$($module.Name)/$suite"
                Write-Host "  FAIL: $suite" -ForegroundColor Red
            }
            else {
                $passedSuites += "$($module.Name)/$suite"
                Write-Host "  PASS: $suite" -ForegroundColor Green
            }
        }
    }

    # Summary
    Write-Host ""
    Write-Host "==> Compliance test summary" -ForegroundColor Cyan
    $passedSuites | ForEach-Object { Write-Host "  PASS: $_" -ForegroundColor Green }
    $failedSuites | ForEach-Object { Write-Host "  FAIL: $_" -ForegroundColor Red }

    if ($failedSuites.Count -gt 0) {
        Write-Host ""
        Write-Host "Compliance tests: FAIL ($($failedSuites.Count) suite(s) failed)" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Compliance tests: PASS ($($passedSuites.Count) suite(s) passed)" -ForegroundColor Green
    exit 0
}
finally {
    foreach ($f in $allPlanBinaries + $allPlanJsonPaths) {
        Remove-Item -Path $f -ErrorAction SilentlyContinue
    }
    foreach ($module in $Modules) {
        $FixtureDir = Join-Path $RepoRoot "modules" $module.Name "compliance" "fixture"
        Remove-Item -Path (Join-Path $FixtureDir ".terraform" "terraform.tfstate") -ErrorAction SilentlyContinue
    }
}
