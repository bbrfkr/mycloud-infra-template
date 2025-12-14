variable "environment_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "image_id" {
  type = string
}

variable "key_pair_name" {
  type    = string
  default = "bbrfkr"
}

variable "bastion_sg_id" {
  type = string
}

variable "flavor_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "external_subnet_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "docker_app_tcp_ports" {
  type = list(number)
}

variable "user_data" {
  type    = string
  default = ""
}