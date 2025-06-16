module "dify_docker" {
  source               = "../../../modules/docker_app"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  // ubuntu-noble-docker
  image_id             = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
  // g1.large
  flavor_id            = "3397ad08-149f-463b-b8f1-a35c36cd8caa"
  volume_size          = 100
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  app_name = "dify-docker"
}
