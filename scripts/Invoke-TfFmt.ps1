#Requires -Version 7.4
<#
.SYNOPSIS
    Checks that all Terraform files are correctly formatted.
.DESCRIPTION
    Runs 'terraform fmt -check -recursive' against the Terraform directory.
    Exits non-zero if any files are not formatted correctly.
.PARAMETER TerraformDir
    Path to the Terraform root module directory. Defaults to the parent of the scripts directory.
.EXAMPLE
    ./Invoke-TfFmt.ps1
    ./Invoke-TfFmt.ps1 -TerraformDir /path/to/terraform
#>
[CmdletBinding()]
param(
    [string]$TerraformDir = (Join-Path $PSScriptRoot "..")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TerraformDir = Resolve-Path $TerraformDir

Write-Host "==> terraform fmt check: $TerraformDir" -ForegroundColor Cyan

terraform fmt -check -recursive $TerraformDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "terraform fmt: FAIL" -ForegroundColor Red
    Write-Host "    Run 'terraform fmt -recursive $TerraformDir' to fix formatting issues." -ForegroundColor Yellow
    exit 1
}

Write-Host "terraform fmt: PASS" -ForegroundColor Green
exit 0
