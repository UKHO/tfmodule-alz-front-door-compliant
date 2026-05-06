# Secrets are Key Vault certificates imported into Front Door.
# They appear under "Secrets" in the Azure Portal and are referenced
# by custom domains that use a CustomerCertificate TLS type.
#
# Prerequisites:
#   - The Front Door profile's system-assigned managed identity (created in
#     frontdoor.tf) must have "Key Vault Certificate User" (or at minimum
#     "Key Vault Secrets User") on the Key Vault, so Front Door can read the
#     certificate.
#   - Pass the *versioned* Key Vault certificate ID to pin a specific version,
#     or the *versionless* ID to always use the latest version.

resource "azurerm_cdn_frontdoor_secret" "this" {
  for_each = var.secrets

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.key_vault_certificate_id
    }
  }
}
