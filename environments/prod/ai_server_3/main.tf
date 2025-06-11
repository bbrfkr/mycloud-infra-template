module "ai_server_3" {
  source               = "../../../modules/ai_server"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "52f99332-94f9-4c65-9799-ff78c3427992"
  image_id             = "1f471caa-d749-40fc-86e6-af157a8d368b"
  resource_suffix      = "3"
  gpu_count = "4"
  model_name = "deepseek-ai/DeepSeek-R1-0528-Qwen3-8B"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}
