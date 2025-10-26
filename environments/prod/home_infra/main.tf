locals {
  docker_image_id = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
  g1_medium_id = "055dc2d5-ad66-4786-a8b2-003695a62dd5"
  g1_2xlarge_id = "fac70312-023e-4b61-9492-5434704140ab"
}

module "home_infra" {
  source                            = "../../../modules/home_infra"
  environment_name                  = data.terraform_remote_state.common.outputs.environment_name
  network_id                        = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id                     = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name              = data.terraform_remote_state.global_common.outputs.external_subnet_name
  registry_image_id                 = local.docker_image_id
  registry_flavor_id                = local.g1_medium_id
  info_collector_image_id           = local.docker_image_id
  info_collector_flavor_id          = local.g1_medium_id
  open_webui_image_id               = local.docker_image_id
  open_webui_flavor_id              = local.g1_medium_id
  openstack_admin_access_key_id     = base64decode(data.openstack_keymanager_secret_v1.openstack_admin_access_key_id.payload)
  openstack_admin_secret_access_key = base64decode(data.openstack_keymanager_secret_v1.openstack_admin_secret_access_key.payload)
  dockerhub_username                = base64decode(data.openstack_keymanager_secret_v1.dockerhub_username.payload)
  dockerhub_password                = base64decode(data.openstack_keymanager_secret_v1.dockerhub_password.payload)
  discord_general_news_hook_url     = base64decode(data.openstack_keymanager_secret_v1.discord_general_news_hook_url.payload)
  discord_it_news_hook_url          = base64decode(data.openstack_keymanager_secret_v1.discord_it_news_hook_url.payload)
  discord_aws_news_hook_url         = base64decode(data.openstack_keymanager_secret_v1.discord_aws_news_hook_url.payload)
  discord_it_event_hook_url         = base64decode(data.openstack_keymanager_secret_v1.discord_it_event_hook_url.payload)
  discord_developersio_hook_url     = base64decode(data.openstack_keymanager_secret_v1.discord_developersio_hook_url.payload)
}
