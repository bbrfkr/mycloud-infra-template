resource "openstack_dns_recordset_v2" "ollama_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "ollama.${openstack_dns_zone_v2.zone.name}"
  description = "for ollama"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "ollama_open_webui_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "open-webui.${openstack_dns_zone_v2.zone.name}"
  description = "for open webui"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_networking_secgroup_v2" "ollama_sg" {
  name        = "${var.environment_name}-ollama-sg"
  description = "${var.environment_name}-ollama-sg"
}

resource "openstack_networking_secgroup_rule_v2" "ollama_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 11434
  port_range_max    = 11434
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ollama_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "ollama_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ollama_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "ollama_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.ollama_sg.id
}

resource "openstack_networking_port_v2" "ollama_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.ollama_sg.id]
}

resource "openstack_compute_instance_v2" "ollama_instance" {
  name      = "${var.environment_name}-ollama"
  flavor_id = var.ollama_flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.ollama_volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }
  network {
    port = openstack_networking_port_v2.ollama_port.id
  }
}

resource "openstack_networking_floatingip_v2" "ollama_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "ollama_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.ollama_fip.address
  port_id     = openstack_networking_port_v2.ollama_port.id
}
