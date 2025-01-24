output "registry_fip" {
  value = openstack_networking_floatingip_v2.registry_fip.address
}

output "ollama_fip" {
  value = openstack_networking_floatingip_v2.ollama_fip.address
}
