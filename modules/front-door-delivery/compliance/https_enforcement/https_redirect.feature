Feature: Routes must enforce HTTPS redirect
  # ADDITIVE GUARDRAIL: No specific ALZ DENY policy targets this Front Door route
  # attribute directly. This control is an org-level best practice to ensure all
  # HTTP traffic is automatically redirected to HTTPS at the edge before reaching
  # any origin, preventing cleartext requests traversing the CDN layer.

  Scenario: Route has HTTPS redirect enabled
    Given I have azurerm_cdn_frontdoor_route defined
    Then its https_redirect_enabled must be "true"
