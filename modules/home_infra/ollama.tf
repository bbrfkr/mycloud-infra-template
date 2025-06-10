resource "openstack_dns_recordset_v2" "ollama_1_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama-1.${openstack_dns_zone_v2.zone.name}"
  description = "for ollama 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "ollama_2_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama-2.${openstack_dns_zone_v2.zone.name}"
  description = "for ollama 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "ollama_3_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama-3.${openstack_dns_zone_v2.zone.name}"
  description = "for ollama 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "ollama_nfs_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama-nfs.${openstack_dns_zone_v2.zone.name}"
  description = "for ollama nfs"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.20"]
}

resource "openstack_objectstorage_container_v1" "ollama_storage_container" {
  region = "RegionOne"
  name   = "${var.environment_name}-ollama-storage"
}
