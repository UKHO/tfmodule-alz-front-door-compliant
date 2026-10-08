locals {
  # The set of domains each route is actually reachable on: the shared default
  # domain (if linked) plus any custom domain keys. Two routes only conflict
  # when they share BOTH a domain and an overlapping pattern — different
  # custom domains can safely reuse the same pattern (e.g. "/*" on each).
  route_domain_keys = {
    for key, route in var.routes : key => toset(concat(
      route.link_to_default_domain ? ["__default_domain__"] : [],
      route.custom_domain_keys != null ? route.custom_domain_keys : []
    ))
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.routes

  name                            = each.value.name
  cdn_frontdoor_endpoint_id       = data.azurerm_cdn_frontdoor_endpoint.shared.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  cdn_frontdoor_origin_ids        = [for origin_key in each.value.origin_keys : azurerm_cdn_frontdoor_origin.this[origin_key].id]
  enabled                         = each.value.enabled
  forwarding_protocol             = each.value.forwarding_protocol
  https_redirect_enabled          = each.value.https_redirect_enabled
  patterns_to_match               = each.value.patterns_to_match
  supported_protocols             = each.value.supported_protocols
  cdn_frontdoor_custom_domain_ids = each.value.custom_domain_keys != null ? [for domain_key in each.value.custom_domain_keys : azurerm_cdn_frontdoor_custom_domain.this[domain_key].id] : []
  link_to_default_domain          = each.value.link_to_default_domain
  cdn_frontdoor_rule_set_ids      = each.value.rule_set_keys != null ? [for rule_set_key in each.value.rule_set_keys : azurerm_cdn_frontdoor_rule_set.this[rule_set_key].id] : []

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }

  lifecycle {
    # Guard against this team's own routes overlapping each other on a shared
    # domain (pure config check, no live Azure lookup needed). Routes bound to
    # different domains are not a conflict even if their patterns match.
    precondition {
      condition = alltrue([
        for other_key, other_route in var.routes : (
          other_key == each.key
          || length(setintersection(local.route_domain_keys[each.key], local.route_domain_keys[other_key])) == 0
          || length(setintersection(toset(each.value.patterns_to_match), toset(other_route.patterns_to_match))) == 0
        )
      ])
      error_message = "Route '${each.value.name}' has patterns_to_match that overlap another route on a shared domain (default domain and/or the same custom domain). Routes: ${join(", ", [for key, route in var.routes : route.name])}."
    }
  }
}
