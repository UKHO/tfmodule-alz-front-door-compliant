# Variable values for terraform-compliance plan generation.
# These are test values only — this file is used to generate a plan JSON for
# terraform-compliance BDD checks. No resources are deployed.
# subscription_id is supplied at runtime by Invoke-TfCompliance.ps1 via -var flag.
#
# All values are set to their policy-compliant state so the compliance suite passes.

origin_groups = {
  default = {
    name                     = "og-compliance-test"
    session_affinity_enabled = false
    load_balancing = {
      sample_size                        = 4
      successful_samples_required        = 3
      additional_latency_in_milliseconds = 0
    }
  }
}

origins = {
  default = {
    name                           = "origin-compliance-test"
    origin_group_key               = "default"
    enabled                        = true
    host_name                      = "compliance.example.com"
    http_port                      = 80
    https_port                     = 443
    origin_host_header             = "compliance.example.com"
    priority                       = 1
    weight                         = 1000
    certificate_name_check_enabled = true
  }
}

routes = {
  default = {
    name                   = "route-compliance-test"
    origin_group_key       = "default"
    origin_keys            = ["default"]
    enabled                = true
    forwarding_protocol    = "HttpsOnly"
    https_redirect_enabled = true
    patterns_to_match      = ["/*"]
    supported_protocols    = ["Https"]
    link_to_default_domain = true
    custom_domain_keys     = ["default"]
  }
}

custom_domains = {
  default = {
    name        = "domain-compliance-test"
    dns_zone_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-dns/providers/Microsoft.Network/dnsZones/compliance.example.com"
    host_name   = "app.compliance.example.com"
    tls = {
      certificate_type    = "ManagedCertificate"
      minimum_tls_version = "TLS11"
    }
  }
}
