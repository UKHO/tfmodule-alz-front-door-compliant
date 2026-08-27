# Variable values for terraform-compliance plan generation.
# These are test values only — this file is used to generate a plan JSON for
# terraform-compliance BDD checks. No resources are deployed.
# subscription_id is supplied at runtime by Invoke-TfCompliance.ps1 via -var flag.

resource_group_name = "rg-frontdoor-platform-compliance"
front_door_name     = "fdplatformcompliancetest"
sku_name            = "Premium_AzureFrontDoor"

waf_policy_name = "wafplatformcompliancetest"
waf_mode        = "Prevention"

shared_endpoints = {
  default = {
    name    = "ep-compliancetest"
    enabled = true
  }
}

tags = {
  environment   = "test"
  "managed-by"  = "platform"
  "cost-centre" = "0000"
}
