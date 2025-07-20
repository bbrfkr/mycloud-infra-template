locals {
  completion_gpu_count = 1
  additional_gpu_count = 1
  vllm_gpu_count       = 4
  vllm_image_id        = "e71eaca8-46b8-4088-92f1-199c8b1c1f0a"
  comfyui_gpu_count    = 2
  comfyui_image_id     = "7e294288-50a0-47ce-be5a-c8bc5995fc43"
  p2_xlarge_id         = "4840358c-4b90-4d54-a97e-f321a646ee6b"
  p2_2xlarge_id        = "85c71275-8bdf-48a1-8d40-699b34f4f7dc"
  p2_4xlarge_id        = "b90287c6-a704-4e8b-983e-7c8133ac56c3"
  p3_4xlarge_id        = "c3ab8bf5-ac6c-4d66-8f5e-9e519ba01cc9"
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
      vllm_command_args = "--gpu-memory-utilization 0.5 --task embedding --trust-remote-code --max-model-len 8192"
      port = 8000
    },
    {
      model_name           = "Qwen/Qwen3-Reranker-0.6B"
      vllm_command_args = "--gpu-memory-utilization 0.5 --task score --max-model-len 8192"
      port = 8001
    },
  ]
}

module "vllm_1" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p3_4xlarge_id
  image_id             = local.vllm_image_id
  resource_suffix      = "1"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 250
  model_name           = "RedHatAI/DeepSeek-R1-Distill-Qwen-32B-FP8-dynamic"
  vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 73728 --max-num-seqs 2 --gpu-memory-utilization 0.85"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "comfyui_1" {
  source               = "../../../modules/comfyui"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_4xlarge_id
  image_id             = local.comfyui_image_id
  resource_suffix      = "1"
  gpu_count            = local.comfyui_gpu_count
  gpu_power_limit      = 250
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

# module "vllm_2" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = local.p2_4xlarge_id
#   image_id             = local.vllm_image_id
#   resource_suffix      = "2"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 125
#   model_name           = "RedHatAI/DeepSeek-R1-Distill-Qwen-32B-FP8-dynamic"
#   vllm_command_args    = "--tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 12288"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }
