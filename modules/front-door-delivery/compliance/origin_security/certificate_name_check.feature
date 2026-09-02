Feature: Origins must have certificate name check enabled
  # ADDITIVE GUARDRAIL: No specific ALZ DENY policy targets this Front Door origin
  # attribute directly. Disabling certificate name check allows Front Door to accept
  # any certificate on the origin, exposing the connection to man-in-the-middle
  # attacks on the Front Door-to-origin leg. This org-level control ensures the
  # origin certificate subject name is always validated against the origin hostname.

  Scenario: Origin has certificate name check enabled
    Given I have azurerm_cdn_frontdoor_origin defined
    Then its certificate_name_check_enabled must be "true"
