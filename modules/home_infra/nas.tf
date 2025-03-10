resource "openstack_dns_recordset_v2" "nas_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "nas.home.dynamis.bbrfkr.net."
  description = "for home nas"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.20"]
}
