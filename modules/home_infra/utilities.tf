resource "openstack_dns_zone_v2" "zone" {
  name        = "home.dynamis.bbrfkr.net."
  email       = "bbrfkr@gmail.com"
  description = "for home infrastructure"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_networking_secgroup_v2" "allow_all_sg" {
  name        = "allow-all"
  description = "allow-all"
}

resource "openstack_networking_secgroup_rule_v2" "allow_all_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.allow_all_sg.id
}
