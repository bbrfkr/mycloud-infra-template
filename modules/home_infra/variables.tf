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
  type    = string
  default = "3419f213-0120-493c-b3c4-c2996ec17b34"
}

variable "info_collector_image_id" {
  type = string
  // ubuntu-noble
  default = "2dac0fd5-8701-4141-9161-8e9d2f31a623"
}

variable "info_collector_flavor_id" {
  type    = string
  default = "3419f213-0120-493c-b3c4-c2996ec17b34"
}

variable "open_webui_image_id" {
  type = string
}

variable "open_webui_flavor_id" {
  type = string
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

variable "discord_general_news_hook_url" {
  type = string
}

variable "discord_it_news_hook_url" {
  type = string
}

variable "discord_aws_news_hook_url" {
  type = string
}

variable "discord_it_event_hook_url" {
  type = string
}

variable "discord_developersio_hook_url" {
  type = string
}

variable "searxng_workers" {
  type    = number
  default = 4
}

variable "searxng_threads" {
  type    = number
  default = 1
}

variable "searxng_image_id" {
  type = string
}

variable "searxng_flavor_id" {
  type = string
}