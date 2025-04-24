# resource "openstack_dns_recordset_v2" "master_lb_rs" {
#   zone_id  = var.zone_id
#   name        = "master.${var.zone_name}"
#   description = "for master lb"
#   ttl         = 600
#   type        = "A"
#   records     = [openstack_lb_loadbalancer_v2.master_lb.vip_address]
# }

# resource "openstack_networking_secgroup_v2" "master_lb_sg" {
#   name        = "${var.environment_name}-hadoop-master-lb-sg"
#   description = "${var.environment_name}-hadoop-master-lb-sg"
# }

# resource "openstack_networking_secgroup_rule_v2" "master_lb_sg_rule_1" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 80
#   port_range_max    = 80
#   remote_ip_prefix  = var.subnet_cidr
#   security_group_id = openstack_networking_secgroup_v2.master_lb_sg.id
# }

resource "openstack_networking_secgroup_v2" "master_sg" {
  name        = "${var.environment_name}-hadoop-master-sg"
  description = "${var.environment_name}-hadoop-master-sg"
}

resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.master_sg.id
}

# resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_2" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 9300
#   port_range_max    = 9300
#   remote_ip_prefix  = var.subnet_cidr
#   security_group_id = openstack_networking_secgroup_v2.master_sg.id
# }

# resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_91" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_group_id   = var.bastion_sg_id
#   security_group_id = openstack_networking_secgroup_v2.master_sg.id
# }

resource "openstack_networking_port_v2" "master_ports" {
  for_each           = toset([for index in range(var.master_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.master_sg.id]
}

resource "openstack_blockstorage_volume_v3" "master_volumes" {
  for_each = toset([for index in range(var.master_count) : tostring(index)])
  name     = "hadoop-master-${each.value}"
  size     = var.master_volume_size
}

resource "openstack_compute_instance_v2" "masters" {
  for_each  = openstack_networking_port_v2.master_ports
  name      = "${var.environment_name}-hadoop-master-${each.key}"
  image_id  = var.image_id
  flavor_id = var.master_flavor_id
  key_pair  = var.key_pair_name
  network {
    port = each.value.id
  }
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.master_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
apt update
apt install -y openjdk-8-jdk
wget -O /tmp/hadoop.tar.gz https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
tar -xvzf /tmp/hadoop.tar.gz -C /usr/local/
ln -s /usr/local/hadoop-3.4.1 /usr/local/hadoop
echo "export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64" >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh
echo "export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop" >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh

echo "export PATH=$PATH:/usr/local/hadoop/bin" >> /etc/profile.d/hadoop.sh
echo "export HADOOP_HOME=/usr/local/hadoop" >> /etc/profile.d/hadoop.sh
EOS
}

resource "openstack_networking_secgroup_v2" "worker_sg" {
  name        = "${var.environment_name}-hadoop-worker-sg"
  description = "${var.environment_name}-hadoop-worker-sg"
}

resource "openstack_networking_secgroup_rule_v2" "worker_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.worker_sg.id
}

# resource "openstack_networking_secgroup_rule_v2" "data_sg_rule_2" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 9300
#   port_range_max    = 9300
#   remote_ip_prefix  = var.subnet_cidr
#   security_group_id = openstack_networking_secgroup_v2.data_sg.id
# }

# resource "openstack_networking_secgroup_rule_v2" "data_sg_rule_91" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_group_id   = var.bastion_sg_id
#   security_group_id = openstack_networking_secgroup_v2.data_sg.id
# }

resource "openstack_networking_port_v2" "worker_ports" {
  for_each           = toset([for index in range(var.data_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.worker_sg.id]
}

resource "openstack_blockstorage_volume_v3" "worker_volumes" {
  for_each = toset([for index in range(var.data_count) : tostring(index)])
  name     = "worker-data-${each.value}"
  size     = var.worker_volume_size
}

resource "openstack_compute_instance_v2" "workers" {
  for_each  = openstack_networking_port_v2.worker_ports
  name      = "${var.environment_name}-hadoop-worker-${each.key}"
  image_id  = var.image_id
  flavor_id = var.worker_flavor_id
  key_pair  = var.key_pair_name
  network {
    port = each.value.id
  }
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.worker_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
apt update
apt install -y openjdk-8-jdk
wget -O /tmp/hadoop.tar.gz https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
tar -xvzf /tmp/hadoop.tar.gz -C /usr/local/
ln -s /usr/local/hadoop-3.4.1 /usr/local/hadoop
echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh
echo "export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop" >> /usr/local/hadoop/etc/hadoop/hadoop-env.sh

echo "export PATH=$PATH:/usr/local/hadoop/bin" >> /etc/profile.d/hadoop.sh
echo "export HADOOP_HOME=/usr/local/hadoop" >> /etc/profile.d/hadoop.sh
EOS
}