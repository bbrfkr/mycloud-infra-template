output "master_lb_vip" {
  value = openstack_lb_loadbalancer_v2.master_lb.vip_address
}

output "master_lb_hostname" {
  value = [for record in openstack_dns_recordset_v2.master_lb_rs.records : record] 
}

output "master_ips" {
  value = [for master in openstack_compute_instance_v2.masters : master.access_ip_v4]  
}

output "data_ips" {
  value = [for data in openstack_compute_instance_v2.data : data.access_ip_v4]  
}