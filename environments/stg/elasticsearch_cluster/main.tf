module "elasticsearch_cluster" {
  source                     = "../../../modules/elasticsearch_cluster"
  environment_name           = data.terraform_remote_state.common.outputs.environment_name
  project_id                 = data.terraform_remote_state.global_common.outputs.project_id
  image_id = var.image_id
  master_flavor_id = var.master_flavor_id
  data_flavor_id = var.data_flavor_id
  network_id = data.terraform_remote_state.networking.outputs.all.network_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
}
