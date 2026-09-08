variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "front_door_profile_name" {
  description = "Name of the shared platform Front Door profile (created by tests/fixture)."
  type        = string
}

variable "front_door_resource_group" {
  description = "Resource group containing the shared Front Door profile (created by tests/fixture)."
  type        = string
}

variable "shared_endpoint_name" {
  description = "Name of the shared platform endpoint (created by tests/fixture)."
  type        = string
}

variable "dns_zone_id" {
  description = "Resource ID of the DNS zone used for custom-domain overlap testing (created by tests/fixture)."
  type        = string
}

variable "dns_zone_host_suffix" {
  description = "DNS zone name appended to each team's custom domain host name (created by tests/fixture; pass its dns_zone_name output here)."
  type        = string
  default     = "overlaptest.internal"
}

variable "team_a_route_patterns" {
  description = "patterns_to_match for team A's route. Must not overlap team_b_route_patterns."
  type        = list(string)
  default     = ["/team-a/*"]
}

variable "team_b_route_patterns" {
  description = "patterns_to_match for team B's route. Must not overlap team_a_route_patterns."
  type        = list(string)
  default     = ["/team-b/*"]
}
