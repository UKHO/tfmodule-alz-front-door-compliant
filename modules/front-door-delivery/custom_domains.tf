resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = var.custom_domains

  name                     = each.value.name
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.shared.id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.certificate_type == "CustomerCertificate" ? each.value.tls.cdn_frontdoor_secret_id : null
  }

  lifecycle {
    # Guard against this team's own custom domains reusing the same
    # host_name (pure config check, no live Azure lookup needed).
    precondition {
      condition = !contains([
        for key, domain in var.custom_domains : domain.host_name
        if key != each.key
      ], each.value.host_name)
      error_message = "Custom domain '${each.value.name}' has host_name '${each.value.host_name}' that duplicates another custom domain defined in this same module call."
    }
  }
}
