module "kubeflow_cluster" {
  source              = "../../../modules/kubeflow_cluster"
  environment_name    = data.terraform_remote_state.common.outputs.environment_name
  project_id          = data.terraform_remote_state.global_common.outputs.project_id
  fixed_network_id    = data.terraform_remote_state.networking.outputs.all.network_id
  fixed_subnet_id     = data.terraform_remote_state.networking.outputs.all.subnet_id
  master_flavor_id    = var.master_flavor_id
  node_flavor_id      = var.node_flavor_id
  node_count          = var.node_count
  zone_id             = data.terraform_remote_state.networking.outputs.all.zone_id
  zone_name           = data.terraform_remote_state.networking.outputs.all.zone_name
  cluster_template_id = var.cluster_template_id
  floating_ip_enabled = var.floating_ip_enabled
}
