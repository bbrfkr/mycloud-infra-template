resource "openstack_networking_secgroup_v2" "docker_app_sg" {
  name        = "${var.environment_name}-${var.app_name}-sg"
  description = "${var.environment_name}-${var.app_name}-sg"
}

resource "openstack_networking_secgroup_rule_v2" "docker_app_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.docker_app_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "docker_app_sg_tcp_rules" {
  for_each          = toset([for port in var.docker_app_tcp_ports : tostring(port)])
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = tonumber(each.value)
  port_range_max    = tonumber(each.value)
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.docker_app_sg.id
}

resource "openstack_networking_floatingip_v2" "docker_app_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_port_v2" "docker_app_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.docker_app_sg.id]
}

resource "openstack_blockstorage_volume_v3" "docker_app_volume" {
  count = var.volume_size == 0 ? 0 : 1
  name  = var.app_name
  size  = var.volume_size
}

resource "openstack_compute_instance_v2" "docker_app_instance" {
  name      = "${var.environment_name}-${var.app_name}"
  image_id  = var.image_id
  flavor_id = var.flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  dynamic block_device {
    for_each = var.volume_size == 0 ? [] : [0]
    content {
      uuid                  = openstack_blockstorage_volume_v3.docker_app_volume[0].id
      source_type           = "volume"
      boot_index            = 1
      destination_type      = "volume"
      delete_on_termination = false
    }
  }
  network {
    port = openstack_networking_port_v2.docker_app_port.id
  }

  user_data = var.user_data
}

resource "openstack_networking_floatingip_associate_v2" "docker_app_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.docker_app_fip.address
  port_id     = openstack_networking_port_v2.docker_app_port.id
}
