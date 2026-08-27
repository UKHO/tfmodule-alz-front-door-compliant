Feature: WAF mode must be Prevention
  # ALZ policy: Deny-Waf-mode
  # Policy definition ID: 425bea59-a659-4cbb-8d31-34499bd030b8
  # Policy set: Enforce-Guardrails-Network (ALZ)
  # Reference: https://www.azadvertizer.net/azpolicyadvertizer/425bea59-a659-4cbb-8d31-34499bd030b8.html
  # This test mirrors a DENY-effect ALZ policy. A non-compliant plan would be
  # blocked by Azure Policy at deployment time.

  Scenario: WAF firewall policy mode is Prevention
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    Then its mode must be "Prevention"
