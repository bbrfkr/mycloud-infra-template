resource "openstack_dns_recordset_v2" "dev_server_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "dev-server.home.dynamis.bbrfkr.net."
  description = "for dev server"
  ttl         = 600
  type        = "A"
  records     = ["192.168.1.39"]
}

resource "openstack_dns_recordset_v2" "ollama_dev_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama-dev.home.dynamis.bbrfkr.net."
  description = "for ollama dev"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "open_webui_dev_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "open-webui-dev.home.dynamis.bbrfkr.net."
  description = "for open webui dev"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}
