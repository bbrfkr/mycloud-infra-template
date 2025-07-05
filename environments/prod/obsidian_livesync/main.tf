locals {
  g1_xlarge_id = "65bd6d8a-8eaa-4f3d-97e4-3d622237b2d2"
  docker_image_id = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
}

module "completion" {
  source               = "../../../modules/docker_app"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.g1_xlarge_id
  image_id             = local.docker_image_id
  app_name             = "obsidian-livesync"
  docker_app_tcp_ports = ["5984"]
  volume_size          = 300
}
