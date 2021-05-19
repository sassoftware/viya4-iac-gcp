variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "subnet" {
  type = string
}

variable "create_public_ip" {
  default = false
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
  default     = { project_name = "viya401", cost_center = "rnd", environment = "dev" }
}

variable "machine_type" {
  default = "m5.4xlarge"
}

variable "user_data" {
  default = ""
}

variable "user_data_type" {
  default = "" # "cloud-config" "startup-script"
}

variable "vm_admin" {
  description = "Login account for VM"
  default     = "googleuser"
}

variable "ssh_public_key" {
  description = "Path to ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_image" {
  default = "ubuntu-os-cloud/ubuntu-2004-lts" # FAMILY/PROJECT glcoud compute images list
}


variable "data_disk_count" {
  default = 0
}

variable "data_disk_size" {
  default = 128
}

variable "data_disk_type" {
  default = "pd-ssd"
}

