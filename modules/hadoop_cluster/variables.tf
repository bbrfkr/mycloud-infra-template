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

variable "master_flavor_id" {
  type = string
}

variable "worker_flavor_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "master_count" {
  type    = number
  default = 1
}

variable "data_count" {
  type    = number
  default = 3
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "master_volume_size" {
  type    = string
  default = 30
}

variable "worker_volume_size" {
  type    = string
  default = 100
}