resource "openstack_dns_recordset_v2" "vllm_1_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "vllm-1.${openstack_dns_zone_v2.zone.name}"
  description = "for vllm 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "vllm_2_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "vllm-2.${openstack_dns_zone_v2.zone.name}"
  description = "for vllm 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "vllm_3_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "vllm-3.${openstack_dns_zone_v2.zone.name}"
  description = "for vllm 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "vllm_nfs_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "aimodel-nfs.${openstack_dns_zone_v2.zone.name}"
  description = "for aimodel nfs"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.20"]
}

resource "openstack_objectstorage_container_v1" "ollama_storage_container" {
  region = "RegionOne"
  name   = "${var.environment_name}-ollama-storage"
}
