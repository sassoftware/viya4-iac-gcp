variable "name" {}
variable "create_filestore" {
   default = false
}
variable "zone" {}
variable "labels" {}
variable "network" {}
variable "capacity" {
   description = "Size in GB"
   default = "1024"
}
/*
variable "host" {}
variable "access_token" {}
variable "cluster_ca_certificate" {}
*/