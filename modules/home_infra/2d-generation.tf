resource "openstack_dns_recordset_v2" "generation_2d_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "generation-2d.${openstack_dns_zone_v2.zone.name}"
  description = "for generation 2d"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "generation_2d_1_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "generation-2d-1.${openstack_dns_zone_v2.zone.name}"
  description = "for generation 2d"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "generation_2d_2_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "generation-2d-2.${openstack_dns_zone_v2.zone.name}"
  description = "for generation 2d"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "generation_2d_3_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "generation-2d-3.${openstack_dns_zone_v2.zone.name}"
  description = "for generation 2d"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_networking_secgroup_v2" "generation_2d_sg" {
  name        = "${var.environment_name}-generation-2d-sg"
  description = "${var.environment_name}-generation-2d-sg"
}

resource "openstack_networking_secgroup_rule_v2" "generation_2d_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 7861
  port_range_max    = 7863
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.generation_2d_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "generation_2d_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2342
  port_range_max    = 2342
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.generation_2d_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "generation_2d_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.generation_2d_sg.id
}

resource "openstack_networking_port_v2" "generation_2d_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.generation_2d_sg.id]
}

# resource "openstack_compute_instance_v2" "generation_2d_instance" {
#   name      = "${var.environment_name}-generation-2d"
#   flavor_id = var.generation_2d_flavor_id
#   key_pair  = var.key_pair_name
#   block_device {
#     uuid                  = var.generation_2d_volume_id
#     source_type           = "volume"
#     boot_index            = 0
#     destination_type      = "volume"
#     delete_on_termination = false
#   }
#   network {
#     port = openstack_networking_port_v2.generation_2d_port.id
#   }
# }

resource "openstack_networking_floatingip_v2" "generation_2d_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "generation_2d_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.generation_2d_fip.address
  port_id     = openstack_networking_port_v2.generation_2d_port.id
}
