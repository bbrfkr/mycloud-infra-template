# s1.large
variable "master_flavor_id" {
  type    = string
  default = "251c99ad-aa44-43ba-a229-7edf91a26e27"
}

# p1.xlarge
variable "node_flavor_id" {
  type    = string
  default = "ccb95ce3-8629-4a46-994d-d9599df8870e"
}

variable "node_count" {
  type = number
}

# bke-gpu-1.26
variable "cluster_template_id" {
  type = string
}

variable "floating_ip_enabled" {
  type = bool
}