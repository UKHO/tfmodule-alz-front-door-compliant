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
  behaviour_on_match        = each.value.behavior_on_match

  actions {
    dynamic "url_redirect" {
      for_each = each.value.actions != null && each.value.actions.url_redirect_action != null ? [each.value.actions.url_redirect_action] : []
      iterator = url_redirect_action
      content {
        redirect_type         = url_redirect_action.value.redirect_type
        redirect_protocol     = url_redirect_action.value.redirect_protocol
        destination_host_name = url_redirect_action.value.destination_host_name
        destination_path      = url_redirect_action.value.destination_path
        query_string          = url_redirect_action.value.query_string
        destination_fragment  = url_redirect_action.value.destination_fragment
      }
    }

    dynamic "url_rewrite" {
      for_each = each.value.actions != null && each.value.actions.url_rewrite_action != null ? [each.value.actions.url_rewrite_action] : []
      iterator = url_rewrite_action
      content {
        source_pattern                  = url_rewrite_action.value.source_pattern
        destination_path                = url_rewrite_action.value.destination_path
        preserve_unmatched_path_enabled = url_rewrite_action.value.preserve_unmatched_path_enabled
      }
    }

    dynamic "route_configuration_override" {
      for_each = each.value.actions != null && each.value.actions.route_configuration_override_action != null ? [each.value.actions.route_configuration_override_action] : []
      iterator = route_configuration_override_action

      content {
        dynamic "origin_group" {
          for_each = route_configuration_override_action.value.origin_group_key != null ? [1] : []
          content {
            cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[route_configuration_override_action.value.origin_group_key].id
            forwarding_protocol           = route_configuration_override_action.value.forwarding_protocol
          }
        }

        caching {
          behaviour               = route_configuration_override_action.value.cache_behavior
          duration                = route_configuration_override_action.value.cache_duration
          compression_enabled     = route_configuration_override_action.value.compression_enabled
          query_string_behaviour  = route_configuration_override_action.value.query_string_behaviour
          query_string_parameters = route_configuration_override_action.value.query_string_parameters
        }
      }
    }

    dynamic "modify_request_header" {
      for_each = each.value.actions != null && each.value.actions.request_header_actions != null ? each.value.actions.request_header_actions : []
      iterator = request_header_action
      content {
        operator     = request_header_action.value.operator
        header_name  = request_header_action.value.header_name
        header_value = request_header_action.value.header_value
      }
    }

    dynamic "modify_response_header" {
      for_each = each.value.actions != null && each.value.actions.response_header_actions != null ? each.value.actions.response_header_actions : []
      iterator = response_header_action
      content {
        operator     = response_header_action.value.operator
        header_name  = response_header_action.value.header_name
        header_value = response_header_action.value.header_value
      }
    }
  }

  conditions {
    dynamic "remote_address" {
      for_each = each.value.conditions != null && each.value.conditions.remote_address_condition != null ? [each.value.conditions.remote_address_condition] : []
      iterator = remote_address_condition
      content {
        operator = remote_address_condition.value.operator
        values   = remote_address_condition.value.values
      }
    }

    dynamic "request_method" {
      for_each = each.value.conditions != null && each.value.conditions.request_method_condition != null ? [each.value.conditions.request_method_condition] : []
      iterator = request_method_condition
      content {
        operator = request_method_condition.value.operator
        values   = request_method_condition.value.values
      }
    }

    dynamic "request_url" {
      for_each = each.value.conditions != null && each.value.conditions.request_url_condition != null ? [each.value.conditions.request_url_condition] : []
      iterator = request_url_condition
      content {
        operator   = request_url_condition.value.operator
        values     = request_url_condition.value.values
        transforms = request_url_condition.value.transforms
      }
    }

    dynamic "request_path" {
      for_each = each.value.conditions != null && each.value.conditions.request_path_condition != null ? [each.value.conditions.request_path_condition] : []
      iterator = request_path_condition
      content {
        operator   = request_path_condition.value.operator
        values     = request_path_condition.value.values
        transforms = request_path_condition.value.transforms
      }
    }
  }
}
