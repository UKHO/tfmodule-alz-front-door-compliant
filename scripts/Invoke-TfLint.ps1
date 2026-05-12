#Requires -Version 7.4
<#
.SYNOPSIS
    Runs TFLint static analysis against the Terraform directory.
.DESCRIPTION
    Runs 'tflint --recursive --format compact' against the Terraform directory.
    Exits non-zero if any linting violations are found.
.PARAMETER TerraformDir
    Path to the Terraform root module directory. Defaults to the parent of the scripts directory.
.EXAMPLE
    ./Invoke-TfLint.ps1
    ./Invoke-TfLint.ps1 -TerraformDir /path/to/terraform
#>
[CmdletBinding()]
param(
    [string]$TerraformDir = (Join-Path $PSScriptRoot "..")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TerraformDir = Resolve-Path $TerraformDir

Write-Host "==> TFLint: $TerraformDir" -ForegroundColor Cyan

Write-Host "  Initialising TFLint plugins..." -ForegroundColor Gray
tflint --chdir $TerraformDir --init
if ($LASTEXITCODE -ne 0) {
    Write-Host "TFLint init: FAIL" -ForegroundColor Red
    exit 1
}

tflint --chdir $TerraformDir --recursive --format compact

if ($LASTEXITCODE -ne 0) {
    Write-Host "TFLint: FAIL" -ForegroundColor Red
    exit 1
}

Write-Host "TFLint: PASS" -ForegroundColor Green
exit 0
