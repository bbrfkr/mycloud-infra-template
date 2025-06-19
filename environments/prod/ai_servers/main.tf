locals {
  completion_gpu_count = 1
  additional_gpu_count = 1
  vllm_gpu_count       = 2
  vllm_image_id        = "50bccebf-20d2-4416-818a-b29c0689d483"
  sd_webui_image_id    = "f6f74206-cbc6-4c2d-af1b-4bab9e7725b8"
  p2_xlarge_id         = "4840358c-4b90-4d54-a97e-f321a646ee6b"
  p2_2xlarge_id        = "85c71275-8bdf-48a1-8d40-699b34f4f7dc"
}

module "completion" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "ccb95ce3-8629-4a46-994d-d9599df8870e"
  image_id             = local.vllm_image_id
  resource_suffix      = "for-completion"
  gpu_count            = local.completion_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  model_name           = "Qwen/Qwen2.5-Coder-1.5B"
}

module "additional" {
  source               = "../../../modules/vllm-multiple"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "ccb95ce3-8629-4a46-994d-d9599df8870e"
  image_id             = local.vllm_image_id
  resource_suffix      = "for-additional"
  gpu_count            = local.additional_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  models_config = [
    {
      model_name           = "nomic-ai/nomic-embed-text-v1.5"
      vllm_command_args = "--gpu-memory-utilization 0.5 --task embedding --trust-remote-code"
      port = 8000
    },
    {
      model_name           = "Qwen/Qwen3-Reranker-0.6B"
      vllm_command_args = "--gpu-memory-utilization 0.5 --task score"
      port = 8001
    },
  ]
}

# module "vllm_1" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = "85c71275-8bdf-48a1-8d40-699b34f4f7dc"
#   image_id             = local.vllm_image_id
#   resource_suffix      = "1"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 250
#   model_name           = "Qwen/Qwen3-32B-FP8"
#   vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 24576"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }

module "vllm_2" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_2xlarge_id
  image_id             = local.vllm_image_id
  resource_suffix      = "2"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 250
  model_name           = "Qwen/Qwen3-32B-FP8"
  vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 24576"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "vllm_3" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "5e27e863-efbf-4ccd-8271-9840eab638e4"
  image_id             = local.vllm_image_id
  resource_suffix      = "3"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 285
  model_name           = "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
  vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 32768"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "vllm_4" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "5e27e863-efbf-4ccd-8271-9840eab638e4"
  image_id             = local.vllm_image_id
  resource_suffix      = "4"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 285
  model_name           = "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
  vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 32768"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "sd_webui_1" {
  source               = "../../../modules/stable_diffusion"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_xlarge_id
  image_id             = local.sd_webui_image_id
  gpu_count            = 1
  gpu_power_limit      = 250
  resource_suffix      = 1
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}
