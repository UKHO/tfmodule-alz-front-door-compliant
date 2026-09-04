#Requires -Version 7.4
<#
.SYNOPSIS
    Runs the front-door-delivery module overlap tests (native `terraform test`, apply mode)
    against a sandbox subscription.
.DESCRIPTION
    Two-phase execution:
      Phase 1 - Prerequisite: deploys tests/fixture/ to create the shared platform Front Door
                profile, endpoint and DNS zone that two front-door-delivery instances (declared
                in tests/main.tf) will both reference — exactly as two delivery teams would.
      Phase 2 - Tests:        runs `terraform test` against the tests/ harness, which stands up
                               both instances in the same apply and asserts they cannot affect or
                               override each other's routes, origins, origin groups, rule sets or
                               custom domains. terraform test auto-destroys the harness resources
                               on completion.
      Cleanup  - always destroys the fixture in the finally block.
.PARAMETER SubscriptionId
    Azure subscription ID for the sandbox environment. Required.
.PARAMETER TestsDir
    Path to the tests/ harness directory. Defaults to <repo-root>/tests.
.EXAMPLE
    ./Invoke-DeliveryOverlapTests.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000001"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [string]$TestsDir = (Join-Path (Join-Path $PSScriptRoot "..") "tests")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TestsDir        = Resolve-Path $TestsDir
$FixtureDir      = Join-Path $TestsDir "fixture"
$ApplyTestDir    = Join-Path $TestsDir "apply"
$runtimeVarFile  = Join-Path $TestsDir "overlap_runtime.tfvars"
$fixtureDeployed = $false

Write-Host "==> Delivery module overlap tests: $TestsDir" -ForegroundColor Cyan
Write-Host "    Subscription: $SubscriptionId" -ForegroundColor Gray

if (-not (Test-Path $ApplyTestDir)) {
    Write-Host "Overlap tests: SKIP (directory not found: $ApplyTestDir)" -ForegroundColor Yellow
    exit 0
}

$env:ARM_SUBSCRIPTION_ID = $SubscriptionId

# Real auth (e.g. OIDC federation via a pipeline AzureCLI@2 step) is signalled by
# ARM_CLIENT_ID and/or ARM_USE_OIDC/ARM_USE_MSI already being set. In that case, leave
# the ARM_* values alone. Otherwise (local dev run), fall back to Azure CLI auth —
# requires an active `az login` session.
$UsingRealAuth = (-not [string]::IsNullOrWhiteSpace($env:ARM_CLIENT_ID)) `
    -or $env:ARM_USE_OIDC -eq "true" `
    -or $env:ARM_USE_MSI -eq "true"

if (-not $UsingRealAuth) {
    $env:ARM_USE_CLI = "true"
}

$testPassed = $false

try {
    # Phase 1: Deploy fixture (shared profile, endpoint, DNS zone prerequisite)

    Write-Host ""
    Write-Host "==> Phase 1: Deploying shared platform fixture..." -ForegroundColor Cyan

    terraform -chdir="$FixtureDir" init -no-color -input=false
    if ($LASTEXITCODE -ne 0) { Write-Host "Overlap tests: FAIL (fixture init failed)" -ForegroundColor Red; exit 1 }

    # Set before apply (not after) so the finally block always attempts a destroy,
    # even if apply fails partway through having already created some resources.
    $fixtureDeployed = $true

    terraform -chdir="$FixtureDir" apply -auto-approve -input=false -no-color `
        -var="subscription_id=$SubscriptionId"
    if ($LASTEXITCODE -ne 0) { Write-Host "Overlap tests: FAIL (fixture apply failed)" -ForegroundColor Red; exit 1 }

    $profileName   = (terraform -chdir="$FixtureDir" output -raw front_door_profile_name).Trim()
    $resourceGroup = (terraform -chdir="$FixtureDir" output -raw front_door_resource_group).Trim()
    $endpointName  = (terraform -chdir="$FixtureDir" output -raw shared_endpoint_name).Trim()
    $dnsZoneId     = (terraform -chdir="$FixtureDir" output -raw dns_zone_id).Trim()
    $dnsZoneName   = (terraform -chdir="$FixtureDir" output -raw dns_zone_name).Trim()

    if ([string]::IsNullOrWhiteSpace($profileName) -or [string]::IsNullOrWhiteSpace($resourceGroup) -or
        [string]::IsNullOrWhiteSpace($endpointName) -or [string]::IsNullOrWhiteSpace($dnsZoneId) -or
        [string]::IsNullOrWhiteSpace($dnsZoneName)) {
        Write-Host "Overlap tests: FAIL (could not read fixture outputs)" -ForegroundColor Red
        exit 1
    }
    Write-Host "    Shared profile:  $profileName" -ForegroundColor Gray
    Write-Host "    Shared endpoint: $endpointName" -ForegroundColor Gray

    # Write runtime var file (things we cannot hard-code in the test file)
    @"
subscription_id           = "$SubscriptionId"
front_door_profile_name   = "$profileName"
front_door_resource_group = "$resourceGroup"
shared_endpoint_name      = "$endpointName"
dns_zone_id               = "$dnsZoneId"
dns_zone_host_suffix      = "$dnsZoneName"
"@ | Set-Content $runtimeVarFile -Encoding utf8

    # Phase 2: Run tests against the two-instance harness

    Write-Host ""
    Write-Host "==> Phase 2: Running overlap tests against tests/ harness..." -ForegroundColor Cyan

    terraform -chdir="$TestsDir" init -backend=false -no-color -input=false
    if ($LASTEXITCODE -ne 0) { Write-Host "Overlap tests: FAIL (harness init failed)" -ForegroundColor Red; exit 1 }

    terraform -chdir="$TestsDir" test `
        -test-directory="apply" `
        -var-file="overlap_runtime.tfvars"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Overlap tests: FAIL" -ForegroundColor Red
        exit 1
    }

    $testPassed = $true
    Write-Host "Overlap tests: PASS" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "Overlap tests: FAIL (exception: $_)" -ForegroundColor Red
    exit 1
}
finally {
    # Always clean up the runtime var file
    Remove-Item $runtimeVarFile -ErrorAction SilentlyContinue

    # Always destroy fixture resources
    if ($fixtureDeployed) {
        Write-Host ""
        Write-Host "==> Destroying shared platform fixture..." -ForegroundColor Cyan
        try {
            terraform -chdir="$FixtureDir" destroy -auto-approve -input=false -no-color `
                -var="subscription_id=$SubscriptionId"
        }
        catch {
            Write-Host "    WARNING: fixture destroy failed: $_" -ForegroundColor Red
            Write-Host "    MANUAL CLEANUP MAY BE REQUIRED: check for 'rg-frontdoor-overlaptest-platform-*' in subscription $SubscriptionId" -ForegroundColor Red
        }
    }

    if (-not $testPassed) {
        Write-Host ""
        Write-Host "    NOTE: terraform test auto-destroys harness resources on completion." -ForegroundColor Yellow
        Write-Host "    If resources remain, check for 'og-overlaptest-*' / 'route-overlaptest-*' resources in subscription $SubscriptionId." -ForegroundColor Yellow
    }
}
