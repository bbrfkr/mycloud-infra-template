resource "openstack_dns_zone_v2" "zone" {
  name        = "mongodb-${var.environment_name}.dynamis.bbrfkr.net."
  email       = "bbrfkr@gmail.com"
  description = "for mongodb"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "node_record_sets" {
  for_each = openstack_networking_port_v2.node_ports
  zone_id  = openstack_dns_zone_v2.zone.id
  name     = "node-${each.key}.mongodb-${var.environment_name}.dynamis.bbrfkr.net."
  ttl      = 600
  type     = "A"
  records  = [each.value.all_fixed_ips[0]]
}

resource "openstack_dns_recordset_v2" "endpoint_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "_mongodb._tcp.endpoint.mongodb-${var.environment_name}.dynamis.bbrfkr.net."
  description = "for mongodb endpoint"
  ttl         = 600
  type        = "SRV"
  records     = [for rs in openstack_dns_recordset_v2.node_record_sets : "0 0 27017 ${rs.name}"]
}

resource "openstack_networking_secgroup_v2" "node_sg" {
  name        = "${var.environment_name}-mongodb-sg"
  description = "${var.environment_name}-mongodb-sg"
}

resource "openstack_networking_secgroup_rule_v2" "node_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 27017
  port_range_max    = 27017
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
  for_each           = toset([for index in range(var.node_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.node_sg.id]
}

resource "openstack_blockstorage_volume_v3" "node_data_volumes" {
  for_each = toset([for index in range(var.node_count) : tostring(index)])
  name     = "mongodb-data-${each.value}"
  size     = var.data_volume_size
}

resource "openstack_compute_instance_v2" "nodes" {
  for_each  = openstack_networking_port_v2.node_ports
  name      = "${var.environment_name}-mongodb-${each.key}"
  flavor_id = var.flavor_id
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
    uuid                  = openstack_blockstorage_volume_v3.node_data_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# install mongodb
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update
apt-get install -y mongodb-org

# mount volume
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/mongodb xfs defaults 0 0' >> /etc/fstab
mount -a
chown mongodb:mongodb /var/lib/mongodb

# kernel parameter tune
echo vm.max_map_count=128000 > /etc/sysctl.d/90-mongodb.conf
sysctl --system

cat <<EOF > /etc/mongod.conf
storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27017
  bindIp: 0.0.0.0
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
replication:
  replSetName: "${var.replica_set_name}"
EOF

# restart mongodb
systemctl restart mongod

# initialize replica set (execute only single node)
node_number=${each.key}
if [ $node_number -eq 0 ] ; then
  sleep 300
  mongosh --eval 'rs.initiate(
    {
      "_id": "${var.replica_set_name}",
      "members": ${jsonencode(
  [for index in range(var.node_count)
    : {
      _id : index,
      host : "node-${index}.mongodb-${var.environment_name}.dynamis.bbrfkr.net"
    }
  ]
)}
    }
  )'
fi
EOS
}
