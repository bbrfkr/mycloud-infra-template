resource "openstack_lb_loadbalancer_v2" "master_lb" {
  vip_subnet_id         = var.subnet_id
  name                  = "${var.environment_name}-elasticsearch-master-lb"
  loadbalancer_provider = "octavia"
  security_group_ids    = [openstack_networking_secgroup_v2.master_lb_sg.id]
}

resource "openstack_lb_listener_v2" "master_listener" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.master_lb.id
  protocol        = "TCP"
  protocol_port   = 80
}

resource "openstack_lb_pool_v2" "master_pool" {
  listener_id = openstack_lb_listener_v2.master_listener.id
  lb_method   = "LEAST_CONNECTIONS"
  protocol    = "TCP"
}

resource "openstack_lb_member_v2" "master_member" {
  for_each      = openstack_networking_port_v2.master_ports
  address       = each.value.all_fixed_ips[0]
  pool_id       = openstack_lb_pool_v2.master_pool.id
  protocol_port = 9200
  subnet_id     = var.subnet_id
}

resource "openstack_dns_zone_v2" "zone" {
  name        = "elasticsearch-${var.environment_name}.dynamis.bbrfkr.net."
  email       = "bbrfkr@gmail.com"
  description = "for elasticsearch"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "master_lb_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "master.elasticsearch-${var.environment_name}.dynamis.bbrfkr.net."
  description = "for master lb"
  ttl         = 600
  type        = "A"
  records     = [openstack_lb_loadbalancer_v2.master_lb.vip_address]
}

resource "openstack_networking_secgroup_v2" "master_lb_sg" {
  name        = "${var.environment_name}-elasticsearch-master-lb-sg"
  description = "${var.environment_name}-elasticsearch-master-lb-sg"
}

resource "openstack_networking_secgroup_rule_v2" "master_lb_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.master_lb_sg.id
}

resource "openstack_networking_secgroup_v2" "master_sg" {
  name        = "${var.environment_name}-elasticsearch-master-sg"
  description = "${var.environment_name}-elasticsearch-master-sg"
}

resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9200
  port_range_max    = 9200
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.master_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9300
  port_range_max    = 9300
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.master_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "master_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.master_sg.id
}

resource "openstack_networking_port_v2" "master_ports" {
  for_each           = toset([for index in range(var.master_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.master_sg.id]
}

resource "openstack_blockstorage_volume_v3" "master_volumes" {
  for_each = toset([for index in range(var.master_count) : tostring(index)])
  name     = "elasticsearch-master-${each.value}"
  size     = var.master_volume_size
}

resource "openstack_compute_instance_v2" "masters" {
  for_each  = openstack_networking_port_v2.master_ports
  name      = "${var.environment_name}-elasticsearch-master-${each.key}"
  flavor_id = var.master_flavor_id
  key_pair  = var.key_pair_name
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
    uuid                  = openstack_blockstorage_volume_v3.master_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# install elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
apt-get update && apt-get install -y apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update && apt-get install -y elasticsearch
systemctl enable elasticsearch

# mount volume
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/elasticsearch xfs defaults 0 0' >> /etc/fstab
mount -a
chown elasticsearch:elasticsearch /var/lib/elasticsearch

# kernel parameter tune
echo vm.max_map_count=262144 > /etc/sysctl.d/90-elasticsearch.conf
sysctl --system

# place elasticsearch config file
cat << EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: ${var.cluster_name}
node.name: master-${each.key}
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: $(curl 169.254.169.254/2009-04-04/meta-data/local-ipv4)
http.port: 9200
discovery.seed_hosts: [${join(",", [for index in range(var.master_count) : openstack_networking_port_v2.master_ports[index].all_fixed_ips[0]])}]
cluster.initial_master_nodes: [${join(",", [for index in range(var.master_count) : "master-${index}"])}]
xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
http.host: 0.0.0.0
node.roles: ["master"]
EOF
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml

# restart elasticsearch
systemctl restart elasticsearch
EOS
}

resource "openstack_networking_secgroup_v2" "data_sg" {
  name        = "${var.environment_name}-elasticsearch-data-sg"
  description = "${var.environment_name}-elasticsearch-data-sg"
}

resource "openstack_networking_secgroup_rule_v2" "data_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9200
  port_range_max    = 9200
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.data_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "data_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9300
  port_range_max    = 9300
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.data_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "data_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.data_sg.id
}

resource "openstack_networking_port_v2" "data_ports" {
  for_each           = toset([for index in range(var.data_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.data_sg.id]
}

resource "openstack_blockstorage_volume_v3" "data_volumes" {
  for_each = toset([for index in range(var.data_count) : tostring(index)])
  name     = "elasticsearch-data-${each.value}"
  size     = var.data_volume_size
}

resource "openstack_compute_instance_v2" "data" {
  for_each  = openstack_networking_port_v2.data_ports
  name      = "${var.environment_name}-elasticsearch-data-${each.key}"
  flavor_id = var.data_flavor_id
  key_pair  = var.key_pair_name
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
    uuid                  = openstack_blockstorage_volume_v3.data_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# install elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
apt-get update && apt-get install -y apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update && apt-get install -y elasticsearch
systemctl enable elasticsearch

# mount volume
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/elasticsearch xfs defaults 0 0' >> /etc/fstab
mount -a
chown elasticsearch:elasticsearch /var/lib/elasticsearch

# kernel parameter tune
echo vm.max_map_count=262144 > /etc/sysctl.d/90-elasticsearch.conf
sysctl --system

# place elasticsearch config file
cat << EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: ${var.cluster_name}
node.name: data-${each.key}
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: $(curl 169.254.169.254/2009-04-04/meta-data/local-ipv4)
http.port: 9200
discovery.seed_hosts: [${join(",", [for index in range(var.master_count) : openstack_networking_port_v2.master_ports[index].all_fixed_ips[0]])}]
xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
http.host: 0.0.0.0
node.roles: ["data"]
EOF
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml

# restart elasticsearch
systemctl restart elasticsearch
EOS
}