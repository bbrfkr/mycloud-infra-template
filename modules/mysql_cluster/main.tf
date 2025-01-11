resource "random_uuid" "replication_group_name" {
}

resource "random_password" "replication_user_password" {
  length           = 16
  special          = true
  override_special = "-_=+"
}

resource "random_password" "proxysql_admin_password" {
  length           = 16
  special          = true
  override_special = "-_=+"
}

resource "random_password" "proxysql_monitor_password" {
  length           = 16
  special          = true
  override_special = "-_=+"
}

resource "random_password" "mysql_admin_password" {
  length           = 16
  special          = true
  override_special = "-_=+"
}

resource "openstack_dns_zone_v2" "zone" {
  name        = "mysql-${var.environment_name}.dynamis.bbrfkr.net."
  email       = "bbrfkr@gmail.com"
  description = "for mysql"
  ttl         = 600
  type        = "PRIMARY"
}

resource "openstack_dns_recordset_v2" "node_record_sets" {
  for_each = openstack_networking_port_v2.node_ports
  zone_id  = openstack_dns_zone_v2.zone.id
  name     = "${var.environment_name}-mysql-${each.key}.mysql-${var.environment_name}.dynamis.bbrfkr.net."
  ttl      = 600
  type     = "A"
  records  = [each.value.all_fixed_ips[0]]
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

resource "openstack_networking_secgroup_rule_v2" "node_sg_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 33062
  port_range_max    = 33062
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
  name     = "mysql-data-${each.value}"
  size     = var.data_volume_size
}

resource "openstack_compute_instance_v2" "nodes" {
  for_each  = openstack_networking_port_v2.node_ports
  name      = "${var.environment_name}-mysql-${each.key}"
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
systemctl enable mysql

# configure mysql
cat > /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF
[mysqld]
user            = mysql
bind-address            = 0.0.0.0
mysqlx-bind-address     = 0.0.0.0

#
# * Fine Tuning
#
key_buffer_size         = 16M
# max_allowed_packet    = 64M
# thread_stack          = 256K
# thread_cache_size       = -1
myisam-recover-options  = BACKUP
# max_connections        = 151
# table_open_cache       = 4000

#
# * Logging and Replication
# general_log_file        = /var/log/mysql/query.log
# general_log             = 1
log_error = /var/log/mysql/error.log
# slow_query_log                = 1
# slow_query_log_file   = /var/log/mysql/mysql-slow.log
# long_query_time = 2
# log-queries-not-using-indexes

max_binlog_size   = 100M
# binlog_do_db          = include_database_name
# binlog_ignore_db      = include_database_name

#
# * replication settings
#
disabled_storage_engines="MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"

server_id=${each.key + 1}
report_host=${each.value.all_fixed_ips[0]}
gtid_mode=ON
enforce_gtid_consistency=ON
binlog_checksum=NONE

log_bin=binlog
log_slave_updates=ON
binlog_format=ROW
master_info_repository=TABLE
relay_log_info_repository=TABLE
transaction_write_set_extraction=XXHASH64

plugin_load_add='group_replication.so'
loose_group_replication_group_name="${random_uuid.replication_group_name.result}"
loose_group_replication_start_on_boot=off
loose_group_replication_local_address="${each.value.all_fixed_ips[0]}:33061"
loose_group_replication_group_seeds="${join(",", [for port in openstack_networking_port_v2.node_ports : "${port.all_fixed_ips[0]}:33061"])}"
loose_group_replication_bootstrap_group=off
loose_group_replication_recovery_get_public_key=1
EOF

systemctl restart mysql
  cat <<EOT | mysql
SET SQL_LOG_BIN=0;
CREATE USER rpl_user@'%' IDENTIFIED BY '${random_password.replication_user_password.result}';
GRANT REPLICATION SLAVE ON *.* TO rpl_user@'%';
GRANT BACKUP_ADMIN ON *.* TO rpl_user@'%';
FLUSH PRIVILEGES;
SET SQL_LOG_BIN=1;
CHANGE REPLICATION SOURCE TO SOURCE_USER='rpl_user', SOURCE_PASSWORD='${random_password.replication_user_password.result}' FOR CHANNEL 'group_replication_recovery';
EOT

if [ ${each.key} -eq 0 ]; then
  cat <<EOT | mysql
CREATE USER 'admin'@'%' IDENTIFIED BY '${random_password.mysql_admin_password.result}';
CREATE USER 'monitor'@'%' IDENTIFIED BY '${random_password.proxysql_monitor_password.result}';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'monitor'@'%';

SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION USER='rpl_user', PASSWORD='${random_password.replication_user_password.result}';
SET GLOBAL group_replication_bootstrap_group=OFF;
EOT
else
  cat <<EOT | mysql
START GROUP_REPLICATION USER='rpl_user', PASSWORD='${random_password.replication_user_password.result}';
EOT
fi
EOS
}

resource "openstack_dns_recordset_v2" "proxysql_record_set" {
  zone_id = openstack_dns_zone_v2.zone.id
  name    = "${var.environment_name}-proxysql.mysql-${var.environment_name}.dynamis.bbrfkr.net."
  ttl     = 600
  type    = "A"
  records = [openstack_networking_port_v2.proxysql_port.all_fixed_ips[0]]
}

resource "openstack_networking_secgroup_v2" "proxysql_sg" {
  name        = "${var.environment_name}-mysql-proxysql-sg"
  description = "${var.environment_name}-mysql-proxysql-sg"
}

resource "openstack_networking_secgroup_rule_v2" "proxysql_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.proxysql_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "proxysql_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3307
  port_range_max    = 3307
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.proxysql_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "proxysql_sg_rule_91" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.proxysql_sg.id
}

resource "openstack_networking_port_v2" "proxysql_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.proxysql_sg.id]
}

resource "openstack_compute_instance_v2" "proxysql" {
  name      = "${var.environment_name}-proxysql"
  flavor_id = var.flavor_id
  key_pair  = var.key_pair_name
  network {
    port = openstack_networking_port_v2.proxysql_port.id
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

# install proxysql
apt-get install -y --no-install-recommends lsb-release wget apt-transport-https ca-certificates gnupg
wget -O - 'https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/repo_pub_key' | apt-key add - 
echo deb https://repo.proxysql.com/ProxySQL/proxysql-2.6.x/$(lsb_release -sc)/ ./ | tee /etc/apt/sources.list.d/proxysql.list
apt update && apt install -y proxysql mysql-client

# congigure proxysql
cat > /etc/proxysql.cnf <<EOT
datadir="/var/lib/proxysql"
errorlog="/var/lib/proxysql/proxysql.log"
admin_variables=
{
        admin_credentials="proxyadmin:${random_password.proxysql_admin_password.result}"
        mysql_ifaces="127.0.0.1:6032;/tmp/proxysql_admin.sock"
}
mysql_variables=
{
        threads=4
        max_connections=2048
        default_query_delay=0
        default_query_timeout=36000000
        have_compress=true
        poll_timeout=2000
        interfaces="0.0.0.0:3306;0.0.0.0:3307"
        default_schema="information_schema"
        stacksize=1048576
        server_version="5.5.30"
        connect_timeout_server=3000
        monitor_username="monitor"
        monitor_password="${random_password.proxysql_monitor_password.result}"
        monitor_history=600000
        monitor_connect_interval=60000
        monitor_ping_interval=10000
        monitor_read_only_interval=1500
        monitor_read_only_timeout=500
        ping_interval_server_msec=120000
        ping_timeout_server=500
        commands_stats=true
        sessions_sort=true
        connect_retries_on_failure=10
}
EOT
systemctl enable proxysql
systemctl start proxysql

sleep 5

cat <<EOT | mysql -uproxyadmin -p'${random_password.proxysql_admin_password.result}' -h127.0.0.1 -P6032
INSERT INTO mysql_users(username,password,default_hostgroup) VALUES ('admin','${random_password.mysql_admin_password.result}',30);
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
INSERT INTO mysql_group_replication_hostgroups (writer_hostgroup,backup_writer_hostgroup,reader_hostgroup,offline_hostgroup,active,max_writers,writer_is_also_reader,max_transactions_behind) VALUES (30,34,31,36,1,1,1,0);
EOT

index=0
for ip in ${join(" ", [for port in openstack_networking_port_v2.node_ports : port.all_fixed_ips[0]])}; do
  if [ $index -eq 0 ]; then
    hostgroup_id=30
  else
    hostgroup_id=31
  fi
  cat <<EOT | mysql -uproxyadmin -p'${random_password.proxysql_admin_password.result}' -h127.0.0.1 -P6032
INSERT INTO mysql_servers (hostgroup_id,hostname,port,comment) VALUES ($hostgroup_id,'$ip',3306,'mysql-$index');
EOT
  index=$(expr $index + 1)
done

cat <<EOT | mysql -uproxyadmin -p'${random_password.proxysql_admin_password.result}' -h127.0.0.1 -P6032
INSERT INTO mysql_hostgroup_attributes (hostgroup_id,servers_defaults) VALUES (31, '{"max_connections":500,"use_ssl":1}');
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
EOT

cat <<EOT | mysql -uproxyadmin -p'${random_password.proxysql_admin_password.result}' -h127.0.0.1 -P6032
INSERT INTO mysql_query_rules (rule_id,active,proxy_port,destination_hostgroup,apply) VALUES (1,1,3306,30,1), (2,1,3307,31,1);
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
EOT
EOS
}

resource "openstack_networking_secgroup_v2" "endpoint_lb_sg" {
  name        = "${var.environment_name}-mysql-endpoint-lb-sg"
  description = "${var.environment_name}-mysql-endpoint-lb-sg"
}

resource "openstack_networking_secgroup_rule_v2" "endpoint_lb_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.endpoint_lb_sg.id
}

resource "openstack_lb_loadbalancer_v2" "read_endpoint_lb" {
  vip_subnet_id         = var.subnet_id
  name                  = "${var.environment_name}-mysql-read-endpoint-lb"
  loadbalancer_provider = "octavia"
  security_group_ids    = [openstack_networking_secgroup_v2.endpoint_lb_sg.id]
}

resource "openstack_lb_listener_v2" "read_endpoint_lb_listener" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.read_endpoint_lb.id
  protocol        = "TCP"
  protocol_port   = 3306
}

resource "openstack_lb_pool_v2" "read_endpoint_lb_pool" {
  listener_id = openstack_lb_listener_v2.read_endpoint_lb_listener.id
  lb_method   = "LEAST_CONNECTIONS"
  protocol    = "TCP"
}

resource "openstack_lb_member_v2" "read_endpoint_lb_member" {
  address       = openstack_networking_port_v2.proxysql_port.all_fixed_ips[0]
  pool_id       = openstack_lb_pool_v2.read_endpoint_lb_pool.id
  protocol_port = 3307
  subnet_id     = var.subnet_id
}

resource "openstack_lb_loadbalancer_v2" "write_endpoint_lb" {
  vip_subnet_id         = var.subnet_id
  name                  = "${var.environment_name}-mysql-write-endpoint-lb"
  loadbalancer_provider = "octavia"
  security_group_ids    = [openstack_networking_secgroup_v2.endpoint_lb_sg.id]
}

resource "openstack_lb_listener_v2" "write_endpoint_lb_listener" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.write_endpoint_lb.id
  protocol        = "TCP"
  protocol_port   = 3306
}

resource "openstack_lb_pool_v2" "write_endpoint_lb_pool" {
  listener_id = openstack_lb_listener_v2.write_endpoint_lb_listener.id
  lb_method   = "LEAST_CONNECTIONS"
  protocol    = "TCP"
}

resource "openstack_lb_member_v2" "write_endpoint_lb_member" {
  address       = openstack_networking_port_v2.proxysql_port.all_fixed_ips[0]
  pool_id       = openstack_lb_pool_v2.write_endpoint_lb_pool.id
  protocol_port = 3306
  subnet_id     = var.subnet_id
}

resource "openstack_dns_recordset_v2" "write_endpoint_record_set" {
  zone_id = openstack_dns_zone_v2.zone.id
  name    = "${var.environment_name}-write.mysql-${var.environment_name}.dynamis.bbrfkr.net."
  ttl     = 600
  type    = "A"
  records = [openstack_lb_loadbalancer_v2.write_endpoint_lb.vip_address]
}

resource "openstack_dns_recordset_v2" "read_endpoint_record_set" {
  zone_id = openstack_dns_zone_v2.zone.id
  name    = "${var.environment_name}-read.mysql-${var.environment_name}.dynamis.bbrfkr.net."
  ttl     = 600
  type    = "A"
  records = [openstack_lb_loadbalancer_v2.read_endpoint_lb.vip_address]
}

