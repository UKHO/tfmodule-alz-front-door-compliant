# Delivery-module overlap tests (native terraform test, apply mode).
#
# Requires Azure credentials (ARM_USE_CLI=true + ARM_SUBSCRIPTION_ID). The
# shared platform prerequisite (tests/fixture/ — profile, endpoint, DNS zone) is
# deployed beforehand by scripts/Invoke-DeliveryOverlapTests.ps1, which injects
# its outputs at runtime via tests/overlap_runtime.tfvars (subscription_id,
# front_door_profile_name, front_door_resource_group, shared_endpoint_name,
# dns_zone_id, dns_zone_host_suffix).
#
# The harness (../main.tf) stands up two front-door-delivery instances —
# module.delivery_team_a and module.delivery_team_b — against that SAME shared
# profile/endpoint/DNS zone, exactly as two independent delivery teams would.
# This suite asserts that neither instance's routes, origins, origin groups,
# rule sets or custom domains can affect or override the other's:
#   - no resource-name collisions
#   - no Azure resource-ID collisions (each instance created genuinely separate
#     objects, not shared/aliased ones)
#   - no patterns_to_match overlap on the shared endpoint
#   - no custom-domain host_name overlap on the shared profile
#   - each route resolves only to its own origin(s)

variables {
  team_a_route_patterns = ["/team-a/*", "/api/team-a/*"]
  team_b_route_patterns = ["/team-b/*", "/api/team-b/*"]
}

run "apply_two_isolated_instances" {
  command = apply

  # --- No resource-name collisions between the two instances ---

  assert {
    condition     = module.delivery_team_a.origin_group_names["apps"] != module.delivery_team_b.origin_group_names["apps"]
    error_message = "Team A and Team B origin group names must not collide on the shared profile."
  }

  assert {
    condition     = module.delivery_team_a.origin_names["app"] != module.delivery_team_b.origin_names["app"]
    error_message = "Team A and Team B origin names must not collide on the shared profile."
  }

  assert {
    condition     = module.delivery_team_a.route_names["route"] != module.delivery_team_b.route_names["route"]
    error_message = "Team A and Team B route names must not collide on the shared endpoint."
  }

  assert {
    condition     = module.delivery_team_a.rule_set_names["rules"] != module.delivery_team_b.rule_set_names["rules"]
    error_message = "Team A and Team B rule set names must not collide on the shared profile."
  }

  assert {
    condition     = module.delivery_team_a.custom_domain_names["app"] != module.delivery_team_b.custom_domain_names["app"]
    error_message = "Team A and Team B custom domain names must not collide on the shared profile."
  }

  # --- No Azure resource-ID collisions (each instance created genuinely
  #     separate objects, not shared/aliased ones) ---

  assert {
    condition = alltrue([
      for id in values(module.delivery_team_a.origin_group_ids) : !contains(values(module.delivery_team_b.origin_group_ids), id)
    ])
    error_message = "Team A and Team B origin groups must be distinct Azure resources."
  }

  assert {
    condition = alltrue([
      for id in values(module.delivery_team_a.origin_ids) : !contains(values(module.delivery_team_b.origin_ids), id)
    ])
    error_message = "Team A and Team B origins must be distinct Azure resources."
  }

  assert {
    condition = alltrue([
      for id in values(module.delivery_team_a.route_ids) : !contains(values(module.delivery_team_b.route_ids), id)
    ])
    error_message = "Team A and Team B routes must be distinct Azure resources."
  }

  assert {
    condition = alltrue([
      for id in values(module.delivery_team_a.rule_set_ids) : !contains(values(module.delivery_team_b.rule_set_ids), id)
    ])
    error_message = "Team A and Team B rule sets must be distinct Azure resources."
  }

  assert {
    condition = alltrue([
      for id in values(module.delivery_team_a.custom_domain_ids) : !contains(values(module.delivery_team_b.custom_domain_ids), id)
    ])
    error_message = "Team A and Team B custom domains must be distinct Azure resources."
  }

  # --- No patterns_to_match overlap on the shared endpoint ---

  assert {
    condition     = length(setintersection(toset(module.delivery_team_a.route_patterns_to_match["route"]), toset(module.delivery_team_b.route_patterns_to_match["route"]))) == 0
    error_message = "Team A and Team B route patterns_to_match must not overlap on the shared endpoint."
  }

  # --- No custom-domain host_name overlap on the shared profile ---

  assert {
    condition     = module.delivery_team_a.custom_domain_host_names["app"] != module.delivery_team_b.custom_domain_host_names["app"]
    error_message = "Team A and Team B custom domain host names must not overlap on the shared profile."
  }

  # --- Each route resolves only to its own origin(s) ---

  assert {
    condition     = toset(module.delivery_team_a.route_origin_ids["route"]) == toset([module.delivery_team_a.origin_ids["app"]])
    error_message = "Team A's route must resolve only to Team A's own origin(s)."
  }

  assert {
    condition     = toset(module.delivery_team_b.route_origin_ids["route"]) == toset([module.delivery_team_b.origin_ids["app"]])
    error_message = "Team B's route must resolve only to Team B's own origin(s)."
  }

  assert {
    condition     = !contains(module.delivery_team_a.route_origin_ids["route"], module.delivery_team_b.origin_ids["app"])
    error_message = "Team A's route must not resolve to Team B's origin."
  }

  assert {
    condition     = !contains(module.delivery_team_b.route_origin_ids["route"], module.delivery_team_a.origin_ids["app"])
    error_message = "Team B's route must not resolve to Team A's origin."
  }
}
