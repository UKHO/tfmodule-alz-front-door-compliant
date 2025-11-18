resource "azurerm_cdn_frontdoor_rule_set" "this" {
  for_each = var.rule_sets

  name                     = each.value.name
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.shared.id
}

resource "azurerm_cdn_frontdoor_rule" "this" {
  for_each = var.rules

  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.this[each.value.rule_set_key].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  dynamic "actions" {
    for_each = [each.value.actions]
    content {
      dynamic "url_redirect_action" {
        for_each = actions.value.url_redirect_action != null ? [actions.value.url_redirect_action] : []
        content {
          redirect_type        = url_redirect_action.value.redirect_type
          redirect_protocol    = url_redirect_action.value.redirect_protocol
          destination_hostname = url_redirect_action.value.destination_hostname
          destination_path     = url_redirect_action.value.destination_path
          query_string         = url_redirect_action.value.query_string
          destination_fragment = url_redirect_action.value.destination_fragment
        }
      }

      dynamic "url_rewrite_action" {
        for_each = actions.value.url_rewrite_action != null ? [actions.value.url_rewrite_action] : []
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }

      dynamic "route_configuration_override_action" {
        for_each = actions.value.route_configuration_override_action != null ? [actions.value.route_configuration_override_action] : []
        content {
          cdn_frontdoor_origin_group_id = route_configuration_override_action.value.origin_group_key != null ? azurerm_cdn_frontdoor_origin_group.this[route_configuration_override_action.value.origin_group_key].id : null
          forwarding_protocol           = route_configuration_override_action.value.forwarding_protocol
          cache_behavior                = route_configuration_override_action.value.cache_behavior
          cache_duration                = route_configuration_override_action.value.cache_duration
          compression_enabled           = route_configuration_override_action.value.compression_enabled
        }
      }

      dynamic "request_header_action" {
        for_each = actions.value.request_header_actions != null ? actions.value.request_header_actions : []
        content {
          header_action = request_header_action.value.header_action
          header_name   = request_header_action.value.header_name
          value         = request_header_action.value.value
        }
      }

      dynamic "response_header_action" {
        for_each = actions.value.response_header_actions != null ? actions.value.response_header_actions : []
        content {
          header_action = response_header_action.value.header_action
          header_name   = response_header_action.value.header_name
          value         = response_header_action.value.value
        }
      }
    }
  }

  dynamic "conditions" {
    for_each = each.value.conditions != null ? [each.value.conditions] : []
    content {
      dynamic "remote_address_condition" {
        for_each = conditions.value.remote_address_condition != null ? [conditions.value.remote_address_condition] : []
        content {
          operator         = remote_address_condition.value.operator
          negate_condition = remote_address_condition.value.negate_condition
          match_values     = remote_address_condition.value.match_values
        }
      }

      dynamic "request_method_condition" {
        for_each = conditions.value.request_method_condition != null ? [conditions.value.request_method_condition] : []
        content {
          operator         = request_method_condition.value.operator
          negate_condition = request_method_condition.value.negate_condition
          match_values     = request_method_condition.value.match_values
        }
      }

      dynamic "request_uri_condition" {
        for_each = conditions.value.request_uri_condition != null ? [conditions.value.request_uri_condition] : []
        content {
          operator         = request_uri_condition.value.operator
          negate_condition = request_uri_condition.value.negate_condition
          match_values     = request_uri_condition.value.match_values
          transforms       = request_uri_condition.value.transforms
        }
      }

      dynamic "url_path_condition" {
        for_each = conditions.value.url_path_condition != null ? [conditions.value.url_path_condition] : []
        content {
          operator         = url_path_condition.value.operator
          negate_condition = url_path_condition.value.negate_condition
          match_values     = url_path_condition.value.match_values
          transforms       = url_path_condition.value.transforms
        }
      }
    }
  }
}
