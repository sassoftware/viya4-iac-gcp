locals {
  # Determine if deployment is multi-zone (either regional or multiple zones)
  is_multizone = length(split(",", var.default_nodepool_locations)) > 1

  # Derive primary/replica zones only when multizone is enabled
  primary_zone = local.is_multizone ? split(",", var.default_nodepool_locations)[0] : null
  replica_zone = local.is_multizone && length(split(",", var.default_nodepool_locations)) > 1 ? split(",", var.default_nodepool_locations)[1] : null
}
