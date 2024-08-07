resource "openstack_networking_network_v2" "network" {
  name           = "${var.environment_name}-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "${var.environment_name}-subnet"
  network_id = openstack_networking_network_v2.network.id
  cidr       = "10.10.0.0/16"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.environment_name}-router-1"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "router_interface_for_public_subnet" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
