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

variable "flavor_id" {
  type = string
  # p1.large
  default = "eed597ed-8bd8-4b3d-9cf8-0b8063501517"
}

variable "image_id" {
  type = string
}

variable "resource_suffix" {
  type    = string
  default = ""
}

variable "gpu_count" {
  type = number
}

variable "gpu_power_limit" {
  type = number
}

variable "huggingface_hf_token" {
  type    = string
  default = ""
}

variable "models_config" {
  type = list(
    object({
      model_name = string
      vllm_command_args = string
      port = number
    })
  )
}
