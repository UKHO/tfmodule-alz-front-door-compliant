# DEPRECATED: Customer-managed certificate support via Key Vault.
# This file is retained for backward compatibility only.
#
# Default behavior: Azure Front Door uses AFD-managed certificates automatically.
# All resources in this file are optional and only created when var.key_vault_name != null.
#
# Legacy use case: If you need customer-managed certificates, provide:
#   - key_vault_name: Name of the Key Vault containing certificates
#   - key_vault_resource_group_name: Resource group of the Key Vault
#   - secrets: Map of certificates to import
#
# Prerequisites for customer-managed certificates:
#   - The Front Door profile's system-assigned managed identity (created in
#     frontdoor.tf) must have "Key Vault Secrets User" on the Key Vault,
#     so Front Door can read the certificate. This is granted below.
#   - Pass the *versioned* Key Vault certificate ID to pin a specific version,
#     or the *versionless* ID to always use the latest version.

data "azurerm_key_vault" "frontdoor" {
  count               = var.key_vault_name != null ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

resource "azurerm_role_assignment" "frontdoor_kv_secrets_user" {
  count                = var.key_vault_name != null ? 1 : 0
  scope                = data.azurerm_key_vault.frontdoor[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_cdn_frontdoor_profile.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [azurerm_cdn_frontdoor_profile.this]
}

resource "azurerm_cdn_frontdoor_secret" "this" {
  for_each = var.key_vault_name != null ? var.secrets : {}

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  depends_on = [azurerm_role_assignment.frontdoor_kv_secrets_user]

  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.key_vault_certificate_id
    }
  }
}
