# Harness for the front-door-delivery overlap tests.
#
# Declares TWO independent front-door-delivery instances — module.delivery_team_a
# and module.delivery_team_b — exactly as two different delivery teams would,
# both pointed at the SAME shared platform profile/endpoint/DNS zone created by
# tests/fixture/. tests/apply/*.tftest.hcl applies this harness and asserts that
# neither instance's routes, origins, origin groups, rule sets or custom domains
# can affect or override the other's.

module "delivery_team_a" {
  source = "../modules/front-door-delivery"

  front_door_profile_name   = var.front_door_profile_name
  front_door_resource_group = var.front_door_resource_group
  shared_endpoint_name      = var.shared_endpoint_name

  origin_groups = {
    apps = {
      name                     = "og-overlaptest-team-a"
      session_affinity_enabled = false
      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 3
        additional_latency_in_milliseconds = 50
      }
    }
  }

  origins = {
    app = {
      name                           = "origin-overlaptest-team-a"
      origin_group_key               = "apps"
      enabled                        = true
      host_name                      = "team-a.overlaptest.example.com"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "team-a.overlaptest.example.com"
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = false
    }
  }

  custom_domains = {
    app = {
      name        = "cd-overlaptest-team-a"
      dns_zone_id = var.dns_zone_id
      host_name   = "team-a.${var.dns_zone_host_suffix}"
      tls = {
        certificate_type = "ManagedCertificate"
      }
    }
  }

  rule_sets = {
    rules = {
      name = "rsoverlaptesta"
    }
  }

  routes = {
    route = {
      name                   = "route-overlaptest-team-a"
      origin_group_key       = "apps"
      origin_keys            = ["app"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = var.team_a_route_patterns
      supported_protocols    = ["Http", "Https"]
      custom_domain_keys     = ["app"]
      link_to_default_domain = true
      rule_set_keys          = ["rules"]
    }
  }
}

module "delivery_team_b" {
  source = "../modules/front-door-delivery"

  front_door_profile_name   = var.front_door_profile_name
  front_door_resource_group = var.front_door_resource_group
  shared_endpoint_name      = var.shared_endpoint_name

  origin_groups = {
    apps = {
      name                     = "og-overlaptest-team-b"
      session_affinity_enabled = false
      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 3
        additional_latency_in_milliseconds = 50
      }
    }
  }

  origins = {
    app = {
      name                           = "origin-overlaptest-team-b"
      origin_group_key               = "apps"
      enabled                        = true
      host_name                      = "team-b.overlaptest.example.com"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "team-b.overlaptest.example.com"
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = false
    }
  }

  custom_domains = {
    app = {
      name        = "cd-overlaptest-team-b"
      dns_zone_id = var.dns_zone_id
      host_name   = "team-b.${var.dns_zone_host_suffix}"
      tls = {
        certificate_type = "ManagedCertificate"
      }
    }
  }

  rule_sets = {
    rules = {
      name = "rsoverlaptestb"
    }
  }

  routes = {
    route = {
      name                   = "route-overlaptest-team-b"
      origin_group_key       = "apps"
      origin_keys            = ["app"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = var.team_b_route_patterns
      supported_protocols    = ["Http", "Https"]
      custom_domain_keys     = ["app"]
      link_to_default_domain = true
      rule_set_keys          = ["rules"]
    }
  }
}
