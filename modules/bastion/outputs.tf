output "bastion_fip" {
  value = openstack_networking_floatingip_v2.bastion_fip.address
}