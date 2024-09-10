output "node_ips" {
  value = [for node in openstack_compute_instance_v2.nodes : node.access_ip_v4]
}