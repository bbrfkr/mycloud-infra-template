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

variable "flavor_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "bastion_sg_id" {
  type = string
}

variable "tidb_node_count" {
  type    = number
  default = 3
}

variable "pd_node_count" {
  type    = number
  default = 3
}

variable "tikv_node_count" {
  type    = number
  default = 3
}

variable "tiflash_node_count" {
  type    = number
  default = 3
}

variable "external_subnet_name" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tikv_data_volume_size" {
  type    = string
  default = 100
}

variable "tiflash_data_volume_size" {
  type    = string
  default = 100
}

variable "controller_data_volume_size" {
  type    = string
  default = 100
}
