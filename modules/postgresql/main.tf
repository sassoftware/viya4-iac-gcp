resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "utility-database" {
  name             = "${var.name}-${random_id.suffix.hex}"

  count            = var.create_postgres ? 1 : 0

  database_version = "POSTGRES_${var.server_version}"
  region           = regex("^[a-z0-9]*-[a-z0-9]*",var.location)

  depends_on       = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier        = var.machine_type  # 30Gb needed to get 600 max_connections default: https://cloud.google.com/sql/docs/postgres/quotas
    disk_size   = var.disk_size_gb
    user_labels = var.labels

    ip_configuration {
       ipv4_enabled    = false
       private_network = var.network
       require_ssl     = var.ssl_enforcement_enabled
    }
  }
}

# There is currently no way to set the admin password for the postgres database instance 
# so we create a separate database and user 
# Also of note:: https://github.com/terraform-providers/terraform-provider-google/issues/3820
  
resource "google_sql_database" "database" {
  name        = var.administrator_login
  instance    = google_sql_database_instance.utility-database[0].name
  count       = var.create_postgres ? 1 : 0
  depends_on  = [google_sql_user.pgadmin]
}

resource "google_sql_user" "pgadmin" {
  name     = var.administrator_login
  count    = var.create_postgres ? 1 : 0
  instance = google_sql_database_instance.utility-database[0].name
  password = var.administrator_password
}


# All about how to use "private ip" to configure access from gke to cloud sql:
# https://cloud.google.com/sql/docs/postgres/private-ip

resource "google_compute_global_address" "private_ip_address" {
  name     = "${var.name}-private-ip-address"
  count    = var.create_postgres ? 1 : 0

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "192.168.0.0"
  prefix_length = 16
  network       = var.network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count    = var.create_postgres ? 1 : 0

  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}


#servicenetworking.googleapis.com 