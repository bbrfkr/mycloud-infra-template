resource "openstack_dns_recordset_v2" "sd_webui_1_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "sd-webui-1.${openstack_dns_zone_v2.zone.name}"
  description = "for sd webui 1"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "sd_webui_2_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "sd-webui-2.${openstack_dns_zone_v2.zone.name}"
  description = "for sd webui 2"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "sd_webui_3_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "sd-webui-3.${openstack_dns_zone_v2.zone.name}"
  description = "for sd webui 3"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}
