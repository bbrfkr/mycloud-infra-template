module "bastion" {
  source               = "../../../modules/bastion"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  image_id             = var.image_id
  flavor_id            = var.flavor_id
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
}
