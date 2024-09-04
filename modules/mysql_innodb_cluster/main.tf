resource "openstack_dns_zone_v2" "zone" {
  name        = "mysql-${var.environment_name}.dynamis.bbrfkr.net."
  email       = "bbrfkr@gmail.com"
  description = "for mysql"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "node_record_sets" {
  for_each = openstack_networking_port_v2.node_ports
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "node-${each.key}.mysql-${var.environment_name}.dynamis.bbrfkr.net."
  ttl         = 600
  type        = "A"
  records     = [each.value.all_fixed_ips[0]]
}

resource "openstack_networking_secgroup_v2" "node_sg" {
  name        = "${var.environment_name}-mysql-nodes-sg"
  description = "${var.environment_name}-mysql-nodes-sg"  
}

resource "openstack_networking_secgroup_rule_v2" "node_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.node_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "node_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 33061
  port_range_max    = 33061
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.node_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "node_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.node_sg.id
}

resource "openstack_networking_port_v2" "node_ports" {
  for_each = toset([for index in range(var.node_count) : tostring(index)])
  network_id = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.node_sg.id]
}

resource "openstack_blockstorage_volume_v3" "node_data_volumes" {
  for_each = toset([for index in range(var.node_count) : tostring(index)])
  name        = "mysql-data-${each.value}"
  size        = var.data_volume_size
}

resource "openstack_compute_instance_v2" "nodes" {
  for_each = openstack_networking_port_v2.node_ports
  name = "${var.environment_name}-mysql-${each.key}"
  flavor_id = var.flavor_id
  key_pair = var.key_pair_name
  network {
    port = each.value.id
  }
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    volume_size           = 50
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.node_data_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# mount volume
mkdir -p /var/lib/mysql
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/mysql xfs defaults 0 0' >> /etc/fstab
mount -a

# install mysql
apt-get update
apt-get install -y mysql-server
EOS
}
