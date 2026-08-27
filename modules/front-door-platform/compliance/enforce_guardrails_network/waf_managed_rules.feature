Feature: WAF must have at least one managed rule set
  # ALZ policy: Deny-Waf-Fw-rules
  # Policy definition ID: 632d3993-e2c0-44ea-a7db-2eca131f356d
  # Policy set: Enforce-Guardrails-Network (ALZ)
  # Reference: https://www.azadvertizer.net/azpolicyadvertizer/632d3993-e2c0-44ea-a7db-2eca131f356d.html
  # This test mirrors a DENY-effect ALZ policy. A non-compliant plan would be
  # blocked by Azure Policy at deployment time.
  # Module defaults: Microsoft_DefaultRuleSet 2.1 + Microsoft_BotManagerRuleSet 1.0

  Scenario: WAF firewall policy has managed rules configured
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    Then it must have managed_rule
