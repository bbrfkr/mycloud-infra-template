# tidb
resource "openstack_networking_secgroup_v2" "tidb_sg" {
  name        = "${var.environment_name}-tidb-pd-sg"
  description = "${var.environment_name}-tidb-pd-sg"
}

resource "openstack_networking_secgroup_rule_v2" "tidb_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.tidb_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "tidb_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.tidb_sg.id
}

resource "openstack_networking_port_v2" "tidb_ports" {
  for_each           = toset([for index in range(var.tidb_node_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.pd_sg.id]
}

resource "openstack_compute_instance_v2" "tidb" {
  for_each  = openstack_networking_port_v2.tidb_ports
  name      = "${var.environment_name}-tidb-tidb-${each.key}"
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
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

mkdir -p /var/lib/tidb/deploy
mkdir -p /var/lib/tidb/data
EOS
}

# pd
resource "openstack_networking_secgroup_v2" "pd_sg" {
  name        = "${var.environment_name}-tidb-pd-sg"
  description = "${var.environment_name}-tidb-pd-sg"
}

resource "openstack_networking_secgroup_rule_v2" "pd_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.pd_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "pd_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.pd_sg.id
}

resource "openstack_networking_port_v2" "pd_ports" {
  for_each           = toset([for index in range(var.pd_node_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.pd_sg.id]
}

resource "openstack_compute_instance_v2" "pd" {
  for_each  = openstack_networking_port_v2.pd_ports
  name      = "${var.environment_name}-tidb-pd-${each.key}"
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
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

mkdir -p /var/lib/tidb/deploy
mkdir -p /var/lib/tidb/data
EOS
}

# tikv
resource "openstack_networking_secgroup_v2" "tikv_sg" {
  name        = "${var.environment_name}-tidb-tikv-sg"
  description = "${var.environment_name}-tidb-tikv-sg"
}

resource "openstack_networking_secgroup_rule_v2" "tikv_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.tikv_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "tikv_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.tikv_sg.id
}

resource "openstack_networking_port_v2" "tikv_ports" {
  for_each           = toset([for index in range(var.tikv_node_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.tikv_sg.id]
}

resource "openstack_blockstorage_volume_v3" "tikv_data_volumes" {
  for_each = toset([for index in range(var.tikv_node_count) : tostring(index)])
  name     = "tikv-data-${each.value}"
  size     = var.tikv_data_volume_size
}

resource "openstack_compute_instance_v2" "tikv" {
  for_each  = openstack_networking_port_v2.tikv_ports
  name      = "${var.environment_name}-tidb-tikv-${each.key}"
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
    uuid                  = openstack_blockstorage_volume_v3.tikv_data_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# mount volume
mkdir -p /var/lib/tidb
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/tidb xfs defaults 0 0' >> /etc/fstab
mount -a

mkdir -p /var/lib/tidb/deploy
mkdir -p /var/lib/tidb/data
EOS
}

# tiflash
resource "openstack_networking_secgroup_v2" "tiflash_sg" {
  name        = "${var.environment_name}-tidb-tiflash-sg"
  description = "${var.environment_name}-tidb-tiflash-sg"
}

resource "openstack_networking_secgroup_rule_v2" "tiflash_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.tiflash_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "tiflash_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.tiflash_sg.id
}

resource "openstack_networking_port_v2" "tiflash_ports" {
  for_each           = toset([for index in range(var.tiflash_node_count) : tostring(index)])
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.tiflash_sg.id]
}

resource "openstack_blockstorage_volume_v3" "tiflash_data_volumes" {
  for_each = toset([for index in range(var.tiflash_node_count) : tostring(index)])
  name     = "tiflash-data-${each.value}"
  size     = var.tiflash_data_volume_size
}

resource "openstack_compute_instance_v2" "tiflash" {
  for_each  = openstack_networking_port_v2.tiflash_ports
  name      = "${var.environment_name}-tidb-tiflash-${each.key}"
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
    uuid                  = openstack_blockstorage_volume_v3.tiflash_data_volumes[each.key].id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# mount volume
mkdir -p /var/lib/tidb
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/tidb xfs defaults 0 0' >> /etc/fstab
mount -a

mkdir -p /var/lib/tidb/deploy
mkdir -p /var/lib/tidb/data
EOS
}

# controller
resource "openstack_networking_secgroup_v2" "controller_sg" {
  name        = "${var.environment_name}-tidb-controller-sg"
  description = "${var.environment_name}-tidb-controller-sg"
}

resource "openstack_networking_secgroup_rule_v2" "controller_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.controller_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.controller_sg.id
}

resource "openstack_networking_port_v2" "controller_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.controller_sg.id]
}

resource "openstack_blockstorage_volume_v3" "controller_data_volume" {
  name = "controller-data"
  size = var.controller_data_volume_size
}

resource "openstack_compute_instance_v2" "controller" {
  name      = "${var.environment_name}-tidb-controller"
  flavor_id = var.flavor_id
  key_pair  = var.key_pair_name
  network {
    port = openstack_networking_port_v2.controller_port.id
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
    uuid                  = openstack_blockstorage_volume_v3.controller_data_volume.id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# mount volume
mkdir -p /var/lib/tidb
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/tidb xfs defaults 0 0' >> /etc/fstab
mount -a

mkdir -p /var/lib/tidb/deploy
mkdir -p /var/lib/tidb/data
EOS
}
