Feature: WAF must have request body inspection enabled
  # Azure built-in policy: "Azure Web Application Firewall on Azure Front Door should
  # have request body inspection enabled"
  # Policy set: Azure Security Benchmark / Microsoft Defender for Cloud
  # ADDITIVE GUARDRAIL: This control is an audit-effect recommendation in Azure Policy
  # and is not enforced as a DENY by the core Enforce-Guardrails-Network ALZ initiative.
  # We enforce it pre-flight here to prevent Defender for Cloud findings post-deployment.
  # The WAF must inspect HTTP request bodies — not only headers, URI, and cookies —
  # to detect threats embedded in the body payload.

  Scenario: WAF firewall policy has request body inspection enabled
    Given I have azurerm_cdn_frontdoor_firewall_policy defined
    Then its request_body_check_enabled must be "true"
