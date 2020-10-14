resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet"
  ip_cidr_range = var.subnet_cidr_block
  region        = var.region
  network       = google_compute_network.vpc.id
}


resource "google_compute_address" "address" {
  count  = 1
  name   = "${var.name}-nat-ip"
  region = var.region
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "~> 1.2"
  project_id    = var.project
  region        = var.region
  create_router = true
  router        = "${var.name}-gke-router"
  network       = google_compute_network.vpc.name
  nat_ips       = [google_compute_address.address[0].self_link]
}
