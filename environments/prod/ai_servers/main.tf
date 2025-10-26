locals {
  completion_gpu_count   = 1
  additional_gpu_count   = 1
  vllm_gpu_count         = 8
  vllm_with_flashinfer_image_id = "64c5bcd6-4577-4bc8-895f-eab3acf62220"
  stable_vllm_image_id   = "04036c92-e690-4354-8802-5ad6903f9749"
  comfyui_gpu_count    = 2
  comfyui_image_id     = "321692b6-c646-4c5e-9925-5740d88e8cfc"
  p1_large_id          = "e80fda3b-b3ff-4e95-96af-8513b7a5e469"
  p1_xlarge_id         = "64295d5b-7e47-415c-813c-85dbf35433ac"
  p1_2xlarge_id        = "0b8bc8af-aea4-4dcc-91ae-c15a5558d2be"
  p2_xlarge_id         = "2425aa0b-5890-48df-8be5-e472b09cda69"
  p2_2xlarge_id        = "fdee135d-30af-4cce-aeeb-43306a63ecce"
  p2_4xlarge_id        = "b08b652b-daba-4ec5-83a6-ba91d62b8b25"
  p2_8xlarge_id        = "ad868ad4-124b-44de-a172-50141315d9ea"
  pc2_2xlarge_id       = "74745db3-ce87-4c03-bead-47ee15c5d684"
}

module "completion" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p1_2xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "for-completion"
  gpu_count            = local.completion_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  model_name           = "Qwen/Qwen2.5-Coder-1.5B"
  vllm_command_args    = "--served-model-name bbrfkr-completion --gpu-memory-utilization 0.85"
}

module "additional" {
  source               = "../../../modules/vllm-multiple"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p1_2xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
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
  flavor_id            = local.pc2_2xlarge_id
  image_id             = local.comfyui_image_id
  resource_suffix      = "1"
  gpu_count            = local.comfyui_gpu_count
  gpu_power_limit      = 150
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "vllm_1" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_8xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "1"
  gpu_count            = local.vllm_gpu_count
  gpu_power_limit      = 150
  model_name           = "openai/gpt-oss-120b"
  vllm_command_args    = "--served-model-name bbrfkr-llm --tensor-parallel-size ${local.vllm_gpu_count} --max-model-len 131072 --max-num-seqs 4 --gpu-memory-utilization 0.85 --async-scheduling"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  vllm_use_flashinfer_mxfp4_bf16_moe = 1
}

# module "vllm_2" {
#   source               = "../../../modules/vllm"
#   environment_name     = data.terraform_remote_state.common.outputs.environment_name
#   network_id           = data.terraform_remote_state.networking.outputs.all.network_id
#   bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
#   external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
#   flavor_id            = local.p2_4xlarge_id
#   image_id             = local.stable_vllm_image_id
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
#   image_id             = local.stable_vllm_image_id
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
#   image_id             = local.stable_vllm_image_id
#   resource_suffix      = "4"
#   gpu_count            = local.vllm_gpu_count
#   gpu_power_limit      = 180
#   model_name           = "openai/gpt-oss-20b"
#   # vllm_command_args    = "--served-model-name bbrfkr-gpt --tensor-parallel-size ${local.vllm_gpu_count} --max-num-seqs 8 --gpu-memory-utilization 0.90"
#   vllm_command_args    = "--invalid-option"
#   huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
# }
