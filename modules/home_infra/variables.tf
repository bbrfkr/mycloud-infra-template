variable "environment_name" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = "bbrfkr"
}

variable "network_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "external_subnet_name" {
  type = string
}

variable "registry_image_id" {
  type = string
  // ubuntu-noble
  default = "2dac0fd5-8701-4141-9161-8e9d2f31a623"
}

variable "registry_flavor_id" {
  type = string
  // ubuntu-noble
  default = "3419f213-0120-493c-b3c4-c2996ec17b34"
}

variable "text_generation_image_id" {
  type = string
  // ubuntu-noble
  default = "2dac0fd5-8701-4141-9161-8e9d2f31a623"
}

variable "text_generation_flavor_id" {
  type = string
  // g1.tiny
  default = "3419f213-0120-493c-b3c4-c2996ec17b34"
}

variable "openstack_admin_access_key_id" {
  type = string
}

variable "openstack_admin_secret_access_key" {
  type = string
}

variable "dockerhub_username" {
  type = string
}

variable "dockerhub_password" {
  type = string
}
