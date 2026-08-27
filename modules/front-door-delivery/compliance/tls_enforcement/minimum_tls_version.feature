Feature: Custom domains must enforce TLS 1.2 or higher
  # Azure built-in policy: "Azure Front Door Standard and Premium should be running
  # minimum TLS version of 1.2"
  # Policy set: Azure Security Benchmark (aligned with ALZ CDN/Front Door controls)
  # ADDITIVE GUARDRAIL: This is an audit-effect recommendation in Azure Policy and
  # is not enforced as a DENY in the core Enforce-Guardrails-Network ALZ initiative.
  # We enforce it pre-flight here to prevent Defender for Cloud findings and to
  # ensure TLS 1.0 and TLS 1.1 are never used on custom domain endpoints.

  Scenario: Custom domain TLS minimum version is TLS12
    Given I have azurerm_cdn_frontdoor_custom_domain defined
    When it has tls
    Then its minimum_tls_version must be "TLS12"
