Feature: Front Door platform resources must have mandatory tags
  # ADDITIVE GUARDRAIL: Organisational tagging governance requirement.
  # No specific ALZ DENY policy enforces these exact tag keys; this is an
  # org-level control to ensure cost attribution and operational ownership.
  # Required tags: environment, managed-by, cost-centre

  Scenario: Front Door profile has environment tag
    Given I have azurerm_cdn_frontdoor_profile defined
    When it has tags
    Then it must contain environment

  Scenario: Front Door profile has managed-by tag
    Given I have azurerm_cdn_frontdoor_profile defined
    When it has tags
    Then it must contain managed-by

  Scenario: Front Door profile has cost-centre tag
    Given I have azurerm_cdn_frontdoor_profile defined
    When it has tags
    Then it must contain cost-centre

  Scenario: WAF policy has environment tag
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    When it has tags
    Then it must contain environment

  Scenario: WAF policy has managed-by tag
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    When it has tags
    Then it must contain managed-by

  Scenario: WAF policy has cost-centre tag
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    When it has tags
    Then it must contain cost-centre
