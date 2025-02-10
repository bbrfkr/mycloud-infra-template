resource "openstack_dns_zone_v2" "zone" {
  name = "kubeflow.${var.zone_name}"
  email       = "bbrfkr@gmail.com"
  description = "for ${var.environment_name} kubeflow"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "zone_ns_rs" {
  zone_id     = var.zone_id
  name        = "kubeflow.${var.zone_name}"
  description = "for kubeflow zone"
  ttl         = 600
  type        = "NS"
  records     = ["endpoint.bbrfkr.net."]
}


resource "openstack_dns_recordset_v2" "kubeflow_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "${openstack_dns_zone_v2.zone.name}"
  description = "for kubeflow"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.1"]
}

resource "openstack_dns_recordset_v2" "argo_server_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "argo-server.${openstack_dns_zone_v2.zone.name}"
  description = "for argocd"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "minio_api_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "minio-api.${openstack_dns_zone_v2.zone.name}"
  description = "for minio api"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "minio_console_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "minio-console.${openstack_dns_zone_v2.zone.name}"
  description = "for minio console"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_containerinfra_cluster_v1" "container_cluster" {
  name                = "${var.environment_name}-kubeflow"
  cluster_template_id = var.cluster_template_id
  node_count          = var.node_count
  keypair             = var.key_pair_name
  master_flavor       = var.master_flavor_id
  flavor              = var.node_flavor_id
  fixed_network       = var.fixed_network_id
  fixed_subnet        = var.fixed_subnet_id
  floating_ip_enabled = var.floating_ip_enabled
}
