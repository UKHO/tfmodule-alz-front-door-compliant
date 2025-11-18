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
}
