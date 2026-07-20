locals {
  zones = [for zone in split(",", var.default_nodepool_locations) : trimspace(zone) if trimspace(zone) != ""]

  # Determine if deployment is multi-zone (2+ explicit zones)
  is_multizone = length(local.zones) > 1

  # Always derive a primary zone when at least one zone is provided.
  # For multi-zone deployments, also derive a replica zone.
  primary_zone = local.zones[0]
  replica_zone = local.is_multizone ? local.zones[1] : null
}
