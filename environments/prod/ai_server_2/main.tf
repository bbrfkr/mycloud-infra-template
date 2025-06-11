locals {
  gpu_count = 3
}

module "ai_server_2" {
  source               = "../../../modules/ai_server"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "ab52f56d-3bd4-478b-ba65-1ccc236e4534"
  image_id             = "1f471caa-d749-40fc-86e6-af157a8d368b"
  resource_suffix      = "2"
  gpu_count = local.gpu_count
  model_name = "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B"
  vllm_command_args = "--tensor-parallel-size ${local.gpu_count} --max-model-len 32768"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}
