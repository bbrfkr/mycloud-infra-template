resource "openstack_dns_recordset_v2" "dev_server_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "dev-server.home.dynamis.bbrfkr.net."
  description = "for dev server"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.39"]
}
