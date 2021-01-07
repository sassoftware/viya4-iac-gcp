locals {
  sql_proxy_namespace = "cloud-sql-proxy"
  cloud_sql_secret = "cloudsql-instance-credentials"
}


resource "random_id" "suffix" {
  count       = var.create_postgres ? 1 : 0
  byte_length = 4
}

resource "google_sql_database_instance" "utility-database" {
  name = "${var.name}-${random_id.suffix[0].hex}"

  count = var.create_postgres ? 1 : 0

  database_version = "POSTGRES_${var.server_version}"
  region           = regex("^[a-z0-9]*-[a-z0-9]*", var.location)

  deletion_protection = false
  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier        = var.machine_type # 30Gb needed to get 600 max_connections default: https://cloud.google.com/sql/docs/postgres/quotas
    disk_size   = var.disk_size_gb
    user_labels = var.labels

    ip_configuration {
      private_network = var.network
      require_ssl     = var.ssl_enforcement_enabled

      ipv4_enabled = length(var.public_access_cidrs) > 0 ? true : false
      dynamic "authorized_networks" {
        for_each = var.public_access_cidrs
        iterator = cidr
        content {
          value = cidr.value
        }
      }
    }
  }
}

# There is currently no way to set the admin password for the postgres database instance 
# so we create a separate database and user 
# Also of note:: https://github.com/terraform-providers/terraform-provider-google/issues/3820

resource "google_sql_database" "database" {
  name       = var.administrator_login
  instance   = google_sql_database_instance.utility-database[0].name
  count      = var.create_postgres ? 1 : 0
  depends_on = [google_sql_user.pgadmin]
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
  name  = "${var.name}-private-ip-address"
  count = var.create_postgres ? 1 : 0

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "192.168.0.0"
  prefix_length = 16
  network       = var.network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.create_postgres ? 1 : 0

  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

# Cloud SQL Proxy
resource "kubernetes_namespace" "cloud_sql_proxy" {
  count = var.create_postgres ? 1 : 0
  metadata {
    name = local.sql_proxy_namespace
  }
}  
resource "kubernetes_secret" "cloudsql-instance-credentials" {
  count = var.create_postgres ? 1 : 0
  metadata {
    name = local.cloud_sql_secret
    namespace = local.sql_proxy_namespace
  }
  data = {
    "credentials.json" = var.service_account_credentials
  }
}

resource "kubernetes_deployment" "sql_proxy_deployment" {
  count = var.create_postgres ? 1 : 0
  metadata {
    labels = {
      app = "sql-proxy"
    }
    name = "sql-proxy-deployment"
    namespace = local.sql_proxy_namespace
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "sql-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "sql-proxy"
        }
      }
      spec {
        container {
          command = [
            "/cloud_sql_proxy",
            "-instances=${google_sql_database_instance.utility-database[0].connection_name}=tcp:0.0.0.0:5432",
            "-credential_file=/secrets/cloudsql/credentials.json",
          ]
          image = "gcr.io/cloudsql-docker/gce-proxy:1.10"
          name = "sql-proxy"
          volume_mount {
            mount_path = "/secrets/cloudsql"
            name = "cloudsql-instance-credentials"
            read_only = true
          }
        }
        
        volume {
          name = "cloudsql-instance-credentials"
          secret {
            secret_name = local.cloud_sql_secret
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sql_proxy_service" {
  count = var.create_postgres ? 1 : 0
  metadata {
    name = "sql-proxy-service"
    namespace = local.sql_proxy_namespace
  }
  spec {
    port {
      port = 5432
      protocol = "TCP"
      target_port = 5432
    }
    selector = {
      app = "sql-proxy"
    }
  }
}
