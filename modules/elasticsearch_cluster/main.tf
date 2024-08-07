resource "openstack_networking_floatingip_v2" "master_lb_fip" {
  pool = var.external_subnet_name
}

resource "openstack_lb_loadbalancer_v2" "master_lb" {
  vip_network_id = var.network_id
  name = "${var.environment_name}-elasticsearch-master-lb"
  loadbalancer_provider = "octavia"
}

resource "openstack_networking_floatingip_associate_v2" "master_lb_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.master_lb_fip.address
  port_id = openstack_lb_loadbalancer_v2.master_lb.vip_port_id
}
