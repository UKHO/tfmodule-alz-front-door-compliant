Feature: WAF must be enabled on Front Door
  # ALZ policy: Deny-Waf-Afd-Enabled
  # Policy definition ID: 055aa869-bc98-4af8-bafc-23f1ab6ffe2c
  # Policy set: Enforce-Guardrails-Network (ALZ)
  # Reference: https://www.azadvertizer.net/azpolicyadvertizer/055aa869-bc98-4af8-bafc-23f1ab6ffe2c.html
  # This test mirrors a DENY-effect ALZ policy. A non-compliant plan would be
  # blocked by Azure Policy at deployment time.

  Scenario: WAF firewall policy is enabled
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    Then its enabled must be "true"
