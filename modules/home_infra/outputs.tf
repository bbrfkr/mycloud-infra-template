output "registry_fip" {
  value = openstack_networking_floatingip_v2.registry_fip.address
}

output "allow_all_security_group_id" {
  value = openstack_networking_secgroup_v2.allow_all_sg.id
}
