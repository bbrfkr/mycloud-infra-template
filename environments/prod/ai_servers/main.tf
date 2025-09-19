locals {
  completion_gpu_count = 1
  additional_gpu_count = 1
  vllm_gpu_count       = 8
  stable_vllm_image_id = "6c8991d8-8be0-4b03-8fbe-fd2364f3ae2d"
  latest_vllm_image_id = "52f80fb5-519f-4b80-9988-b735ea032687"
  comfyui_gpu_count    = 4
  comfyui_image_id     = "321692b6-c646-4c5e-9925-5740d88e8cfc"
  p2_xlarge_id         = "4840358c-4b90-4d54-a97e-f321a646ee6b"
  p2_2xlarge_id        = "e1ec83db-c13e-47ea-a7e9-7d1a3d085755"
  p2_3xlarge_id        = "981636a2-41bc-4e98-9582-b4dba1cab03d"
  p2_4xlarge_id        = "b90287c6-a704-4e8b-983e-7c8133ac56c3"
  p2_8xlarge_id        = "5a43882e-b912-43c4-bf18-372adfc89e75"
  p3_2xlarge_id        = "5e27e863-efbf-4ccd-8271-9840eab638e4"
  p3_4xlarge_id        = "c3ab8bf5-ac6c-4d66-8f5e-9e519ba01cc9"
}

module "completion" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "ccb95ce3-8629-4a46-994d-d9599df8870e"
  image_id             = local.stable_vllm_image_id
  resource_suffix      = "for-completion"
  gpu_count            = local.completion_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  model_name           = "Qwen/Qwen2.5-Coder-1.5B"
  vllm_command_args    = "--served-model-name bbrfkr-completion"
}

module "additional" {
  source               = "../../../modules/vllm-multiple"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "ccb95ce3-8629-4a46-994d-d9599df8870e"
  image_id             = local.stable_vllm_image_id
  resource_suffix      = "for-additional"
  gpu_count            = local.additional_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  models_config = [
    {
      model_name           = "nomic-ai/nomic-embed-text-v2-moe"
      vllm_command_args = "--served-model-name bbrfkr-embedding --gpu-memory-utilization 0.40 --runner pooling --convert embed --trust-remote-code --max-model-len 1572864"
      port = 8000
    },
    {
      model_name           = "Qwen/Qwen3-Reranker-0.6B"
      vllm_command_args = "--served-model-name bbrfkr-reranker --gpu-memory-utilization 0.40 --task score --max-model-len 8192"
      port = 8001
    },
  ]
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
  gpu_power_limit      = 180
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "vllm_1" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_8xlarge_id
  image_id             = local.latest_vllm_image_id
  resource_suffix      = "1"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 100
  model_name           = "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8"
  vllm_command_args    = "--served-model-name bbrfkr-llm --tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 122880 --enable-expert-parallel --max-num-seqs 4 --gpu-memory-utilization 0.85"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

# module "vllm_2" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = local.p2_4xlarge_id
#   image_id             = local.latest_vllm_image_id
#   resource_suffix      = "2"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 180
#   model_name           = "openai/gpt-oss-20b"
#   vllm_command_args    = "--served-model-name bbrfkr-gpt --tensor-parallel-size ${local.vllm_gpu_count} --max-num-seqs 8 --gpu-memory-utilization 0.85"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }

# module "vllm_3" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = local.p2_2xlarge_id
#   image_id             = local.latest_vllm_image_id
#   resource_suffix      = "3"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 180
#   model_name           = "openai/gpt-oss-20b"
#   # vllm_command_args    = "--served-model-name bbrfkr-gpt --tensor-parallel-size ${local.vllm_gpu_count} --max-num-seqs 8 --gpu-memory-utilization 0.90"
#   vllm_command_args    = "--invalid-option"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }

# module "vllm_4" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = local.p2_2xlarge_id
#   image_id             = local.latest_vllm_image_id
#   resource_suffix      = "4"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 180
#   model_name           = "openai/gpt-oss-20b"
#   # vllm_command_args    = "--served-model-name bbrfkr-gpt --tensor-parallel-size ${local.vllm_gpu_count} --max-num-seqs 8 --gpu-memory-utilization 0.90"
#   vllm_command_args    = "--invalid-option"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }
