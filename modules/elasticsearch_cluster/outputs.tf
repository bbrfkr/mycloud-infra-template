output "master_lb_fip" {
  value = openstack_networking_floatingip_v2.master_lb_fip.address
}