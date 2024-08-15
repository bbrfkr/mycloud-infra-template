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
  type = string
  default = "bbrfkr"
}

variable "flavor_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "node_count" {
  type = number
  default = 3
}

variable "subnet_cidr" {
  type = string  
}

variable "subnet_id" {
  type = string  
}

variable "data_volume_size" {
  type = string
  default = 100
}

variable "replica_set_name" {
  type = string
  default = "rs0"
}