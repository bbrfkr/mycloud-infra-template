resource "openstack_dns_recordset_v2" "aimodel_nfs_01_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "aimodel-nfs-01.${openstack_dns_zone_v2.zone.name}"
  description = "for aimodel nfs 01"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.16"]
}

resource "openstack_dns_recordset_v2" "aimodel_nfs_02_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "aimodel-nfs-02.${openstack_dns_zone_v2.zone.name}"
  description = "for aimodel nfs 02"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.17"]
}

# resource "openstack_objectstorage_container_v1" "ollama_storage_container" {
#   region = "RegionOne"
#   name   = "${var.environment_name}-ollama-storage"
# }
