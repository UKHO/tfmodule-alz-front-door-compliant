Feature: Front Door must use Premium SKU
  # ADDITIVE GUARDRAIL: No specific ALZ DENY policy mandates Premium SKU directly,
  # but Premium is required to satisfy the WAF managed rules requirement
  # (Deny-Waf-Fw-rules, 632d3993) and to enable Private Link for origin security.
  # This module enforces Premium_AzureFrontDoor as a hard module-level requirement.

  Scenario: Front Door profile uses Premium SKU
    Given I have azurerm_cdn_frontdoor_profile defined
    Then its sku_name must be "Premium_AzureFrontDoor"
