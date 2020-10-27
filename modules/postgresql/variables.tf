variable "name" {}
variable "location" {}
variable "labels" {}
variable "network" {}
variable "create_postgres" {
  description = "Boolean flag to create Google Cloud Postgres Instance"
  default     = true
}



variable "machine_type" {
  description = "The machine type to use. Postgres supports only shared-core machine types such as db-f1-micro, and custom machine types such as db-custom-2-13312."
  default     = "db-custom-8-30720"
}
variable "disk_size_gb" {
  description = "Minimum Storage Size."
  default     = 10
}

variable "administrator_login" {
  description = "The Administrator Login for the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = "pgadmin"
}

variable "administrator_password" {
  description = "The Password associated with the postgres_administrator_login for the PostgreSQL Server."
  default     = null
}

variable "server_version" {
  description = "Specifies the version of PostgreSQL to use. Valid values are 9.6, 10, 11, and 12."
  default     = "11"
}

variable "ssl_enforcement_enabled" {
  description = "Specifies if SSL should be enforced on connections."
  default     = true
}

variable "create_public_ip" {
  description = "Allow out-of-network access."
  default     = false

}

variable "public_access_cidrs" {
  type    = list(string)
  default = null
}
