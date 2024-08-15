output "bastion_fip" {
  value = openstack_networking_floatingip_v2.bastion_fip.address
}

output "bastion_sg_id" {
  value = openstack_networking_secgroup_v2.bastion_sg.id
}