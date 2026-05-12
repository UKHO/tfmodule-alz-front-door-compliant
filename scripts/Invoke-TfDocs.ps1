#Requires -Version 7.4
<#
.SYNOPSIS
    Checks that terraform-docs generated content in README.md is up to date.
.DESCRIPTION
    Runs 'terraform-docs' with --output-check flag against each module in the modules/
    directory. Exits non-zero if any README.md differs from what terraform-docs would generate.
.PARAMETER ModulesDir
    Path to the directory containing Terraform modules. Defaults to modules/ relative to the scripts directory.
.EXAMPLE
    ./Invoke-TfDocs.ps1
    ./Invoke-TfDocs.ps1 -ModulesDir /path/to/modules
#>
[CmdletBinding()]
param(
    [string]$ModulesDir = (Join-Path $PSScriptRoot ".." "modules")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ModulesDir = Resolve-Path $ModulesDir
$failed = $false

foreach ($moduleDir in (Get-ChildItem -Path $ModulesDir -Directory)) {
    Write-Host "==> terraform-docs check: $($moduleDir.Name)" -ForegroundColor Cyan

    terraform-docs --output-check --output-file README.md $moduleDir.FullName

    if ($LASTEXITCODE -ne 0) {
        Write-Host "terraform-docs: FAIL — $($moduleDir.Name)/README.md is out of date." -ForegroundColor Red
        Write-Host "    Run 'terraform-docs $($moduleDir.FullName)' to regenerate." -ForegroundColor Yellow
        $failed = $true
        continue
    }

    Write-Host "terraform-docs: PASS ($($moduleDir.Name))" -ForegroundColor Green
}

if ($failed) {
    exit 1
}

exit 0
