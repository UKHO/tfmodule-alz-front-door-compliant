#Requires -Version 7.4
<#
.SYNOPSIS
    Local CI equivalent — runs all quality checks in the same order as the Azure DevOps pipeline.
.DESCRIPTION
    Runs the following checks in sequence:
      1. terraform fmt check
      2. TFLint
      3. terraform validate
      4. terraform-docs check

    Exits non-zero if any check fails. Use -ContinueOnError to run all checks even if
    earlier ones fail (useful to see all issues at once).
.PARAMETER ContinueOnError
    If specified, continues running all checks even if an earlier check fails.
    The exit code will still be non-zero if any check failed.
.EXAMPLE
    ./Invoke-CiChecks.ps1
    ./Invoke-CiChecks.ps1 -ContinueOnError
#>
[CmdletBinding()]
param(
    [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptsDir  = $PSScriptRoot
$RepoRoot    = Resolve-Path (Join-Path $PSScriptRoot "..")
$ModulesDir  = Join-Path $RepoRoot "modules"

# ─── Check tracking ───────────────────────────────────────────────────────────

$results = [ordered]@{}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    Write-Host ""
    Write-Host "━━━ $Name ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White

    try {
        & $ScriptBlock
        $exitCode = $LASTEXITCODE
    }
    catch {
        Write-Host "    Exception: $_" -ForegroundColor Red
        $exitCode = 1
    }

    if ($exitCode -eq 0 -or $null -eq $exitCode) {
        $results[$Name] = "PASS"
    }
    else {
        $results[$Name] = "FAIL"
        if (-not $ContinueOnError) {
            Write-Host ""
            Write-Host "Stopping at '$Name'. Use -ContinueOnError to run all checks." -ForegroundColor Yellow
            Show-Summary
            exit 1
        }
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "━━━ CI SUMMARY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
    foreach ($check in $results.GetEnumerator()) {
        $colour = if ($check.Value -eq "PASS") { "Green" } else { "Red" }
        Write-Host ("  {0,-35} {1}" -f $check.Key, $check.Value) -ForegroundColor $colour
    }
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor White
}

# ─── Run checks ───────────────────────────────────────────────────────────────

Invoke-Check "terraform fmt" {
    & "$ScriptsDir/Invoke-TfFmt.ps1" -TerraformDir $ModulesDir
}

Invoke-Check "TFLint" {
    & "$ScriptsDir/Invoke-TfLint.ps1" -TerraformDir $ModulesDir
}

Invoke-Check "terraform validate" {
    & "$ScriptsDir/Invoke-TfValidate.ps1" -ModulesDir $ModulesDir
}

Invoke-Check "terraform-docs" {
    & "$ScriptsDir/Invoke-TfDocs.ps1" -ModulesDir $ModulesDir
}

# ─── Final result ─────────────────────────────────────────────────────────────

Show-Summary

$failedChecks = @($results.Values | Where-Object { $_ -eq "FAIL" })

if ($failedChecks.Count -gt 0) {
    Write-Host ""
    Write-Host "CI RESULT: FAIL ($($failedChecks.Count) check(s) failed)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "CI RESULT: PASS" -ForegroundColor Green
exit 0
