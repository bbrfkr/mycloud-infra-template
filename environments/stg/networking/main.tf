module "networking" {
  source                     = "../../../modules/networking"
  environment_name           = data.terraform_remote_state.common.outputs.environment_name
  project_id                 = data.terraform_remote_state.global_common.outputs.project_id
  external_network_id        = data.terraform_remote_state.global_common.outputs.external_network_id
}
