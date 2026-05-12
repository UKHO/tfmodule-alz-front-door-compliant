#Requires -Version 7.4
<#
.SYNOPSIS
    Validates Terraform configuration without connecting to any backend or provider.
.DESCRIPTION
    Runs 'terraform init -backend=false' then 'terraform validate' against each module
    in the modules/ directory. Exits non-zero on any validate errors.
.PARAMETER ModulesDir
    Path to the directory containing Terraform modules. Defaults to modules/ relative to the scripts directory.
.EXAMPLE
    ./Invoke-TfValidate.ps1
    ./Invoke-TfValidate.ps1 -ModulesDir /path/to/modules
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
    Write-Host "==> terraform validate: $($moduleDir.Name)" -ForegroundColor Cyan

    Write-Host "    Initialising (no backend)..." -ForegroundColor Gray
    terraform -chdir="$($moduleDir.FullName)" init -backend=false -input=false

    if ($LASTEXITCODE -ne 0) {
        Write-Host "terraform validate: FAIL (init failed for $($moduleDir.Name))" -ForegroundColor Red
        $failed = $true
        continue
    }

    terraform -chdir="$($moduleDir.FullName)" validate

    if ($LASTEXITCODE -ne 0) {
        Write-Host "terraform validate: FAIL ($($moduleDir.Name))" -ForegroundColor Red
        $failed = $true
        continue
    }

    Write-Host "terraform validate: PASS ($($moduleDir.Name))" -ForegroundColor Green
}

if ($failed) {
    exit 1
}

exit 0
