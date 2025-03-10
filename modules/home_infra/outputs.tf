output "registry_fip" {
  value = openstack_networking_floatingip_v2.registry_fip.address
}

output "ollama_fip" {
  value = openstack_networking_floatingip_v2.ollama_fip.address
}

output "generation_2d_fip" {
  value = openstack_networking_floatingip_v2.generation_2d_fip.address
}

output "generation_3d_fip" {
  value = openstack_networking_floatingip_v2.generation_3d_fip.address
}

output "gpu_workbench_fip" {
  value = openstack_networking_floatingip_v2.gpu_workbench_fip.address
}
