variable "environment_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "zone_name" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = "bbrfkr"
}

variable "master_flavor_id" {
  type = string
}

variable "node_flavor_id" {
  type = string
}

variable "node_count" {
  type    = number
  default = 1
}

variable "cluster_template_id" {
  type = string
}

variable "floating_ip_enabled" {
  type    = bool
  default = false
}

variable "fixed_network_id" {
  type = string
}

variable "fixed_subnet_id" {
  type = string
}
