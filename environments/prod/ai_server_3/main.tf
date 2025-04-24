module "ai_server_3" {
  source               = "../../../modules/ai_server"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = "52f99332-94f9-4c65-9799-ff78c3427992"
  image_id             = "1c521c46-e6a2-43db-8ff1-260fc07c9276"
  ollama_volume_size = 500
  resource_suffix      = "3"
}
