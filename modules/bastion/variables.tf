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

variable "external_subnet_name" {
  type = string  
}