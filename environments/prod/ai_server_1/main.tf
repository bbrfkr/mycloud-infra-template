locals {
  gpu_count = 1
}

module "ai_server_1" {
  source               = "../../../modules/ai_server"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "1567845b-f97a-4613-83ab-c454e70b6122"
  image_id             = "1f471caa-d749-40fc-86e6-af157a8d368b"
  resource_suffix      = "1"
  gpu_count = local.gpu_count
  model_name = "Qwen/Qwen2.5-Coder-3B"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}
