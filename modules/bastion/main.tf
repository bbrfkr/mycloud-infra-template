resource "openstack_networking_secgroup_v2" "bastion_sg" {
  name        = "${var.environment_name}-bastion-sg"
  description = "${var.environment_name}-bastion-sg"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

resource "openstack_networking_floatingip_v2" "bastion_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_port_v2" "bastion_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.bastion_sg.id]
}

resource "openstack_compute_instance_v2" "bastion_instance" {
  name      = "${var.environment_name}-bastion"
  flavor_id = var.flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    volume_size           = 100
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    port = openstack_networking_port_v2.bastion_port.id
  }
}

resource "openstack_networking_floatingip_associate_v2" "bastion_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.bastion_fip.address
  port_id     = openstack_networking_port_v2.bastion_port.id
}