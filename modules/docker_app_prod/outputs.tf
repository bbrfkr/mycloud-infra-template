output "docker_app_fip" {
  value = openstack_networking_floatingip_v2.docker_app_fip.address
}

output "docker_app_sg_id" {
  value = openstack_networking_secgroup_v2.docker_app_sg.id
}