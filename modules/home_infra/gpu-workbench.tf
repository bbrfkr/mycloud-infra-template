resource "openstack_networking_secgroup_v2" "gpu_workbench_sg" {
  name        = "${var.environment_name}-gpu-workbench-sg"
  description = "${var.environment_name}-gpu-workbench-sg"
}

resource "openstack_networking_secgroup_rule_v2" "gpu_workbench_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.gpu_workbench_sg.id
}

resource "openstack_networking_port_v2" "gpu_workbench_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.gpu_workbench_sg.id]
}

resource "openstack_compute_instance_v2" "gpu_workbench_instance" {
  name      = "${var.environment_name}-gpu-workbench"
  flavor_id = var.gpu_workbench_flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.gpu_workbench_volume_id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = false
  }
  network {
    port = openstack_networking_port_v2.gpu_workbench_port.id
  }
}

resource "openstack_networking_floatingip_v2" "gpu_workbench_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "gpu_workbench_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.gpu_workbench_fip.address
  port_id     = openstack_networking_port_v2.gpu_workbench_port.id
}
