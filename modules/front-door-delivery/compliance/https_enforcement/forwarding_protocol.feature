Feature: Routes must forward traffic to origins over HTTPS only
  # ADDITIVE GUARDRAIL: No specific ALZ DENY policy targets this Front Door route
  # attribute directly. This control is an org-level best practice to ensure that
  # the hop between the Front Door edge PoP and the origin backend is always
  # encrypted. Using "MatchRequest" or "HttpOnly" would permit cleartext forwarding.

  Scenario: Route forwarding protocol is HttpsOnly
    Given I have azurerm_cdn_frontdoor_route defined
    Then its forwarding_protocol must be "HttpsOnly"
