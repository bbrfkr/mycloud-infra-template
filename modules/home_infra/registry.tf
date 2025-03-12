resource "openstack_networking_secgroup_v2" "registry_sg" {
  name        = "${var.environment_name}-registry-sg"
  description = "${var.environment_name}-registry-sg"
}

resource "openstack_networking_secgroup_rule_v2" "registry_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5000
  port_range_max    = 5001
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.registry_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "registry_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.registry_sg.id
}

resource "openstack_networking_floatingip_v2" "registry_fip" {
  pool = var.external_subnet_name
}

resource "openstack_dns_recordset_v2" "registry_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "registry.${openstack_dns_zone_v2.zone.name}"
  description = "for registry"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_dns_recordset_v2" "registry_for_push_rs" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "registry-for-push.${openstack_dns_zone_v2.zone.name}"
  description = "for registry-for-push"
  ttl         = 600
  type        = "CNAME"
  records     = ["prd-router.dynamis.bbrfkr.net."]
}

resource "openstack_networking_port_v2" "registry_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.registry_sg.id]
}

resource "openstack_compute_instance_v2" "registry_instance" {
  name      = "${var.environment_name}-registry"
  image_id = var.registry_image_id
  flavor_id = var.registry_flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.registry_image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  network {
    port = openstack_networking_port_v2.registry_port.id
  }
  user_data = <<EOS
#!/bin/sh
mkdir -p /var/lib/registry
mkdir -p /var/lib/registry-for-push
cat <<EOF > /var/lib/registry/config.yml
version: 0.1
log:
  accesslog:
    disabled: true
  level: info
  formatter: json
  fields:
    service: registry
    environment: prod
storage:
  s3:
    accesskey: ${var.openstack_admin_access_key_id}
    secretkey: ${var.openstack_admin_secret_access_key}
    region: nova
    regionendpoint: https://swift.dynamis.bbrfkr.net
    forcepathstyle: true
    bucket: ${openstack_objectstorage_container_v1.registry_container.name}
    loglevel: info
  delete:
    enabled: false
http:
  addr: 0.0.0.0:5000
proxy:
  remoteurl: https://registry-1.docker.io
  username: ${var.dockerhub_username}
  password: ${var.dockerhub_password}
EOF
cat <<EOF > /var/lib/registry-for-push/config.yml
version: 0.1
log:
  accesslog:
    disabled: true
  level: info
  formatter: json
  fields:
    service: registry-for-push
    environment: prod
storage:
  s3:
    accesskey: ${var.openstack_admin_access_key_id}
    secretkey: ${var.openstack_admin_secret_access_key}
    region: nova
    regionendpoint: https://swift.dynamis.bbrfkr.net
    forcepathstyle: true
    bucket: ${openstack_objectstorage_container_v1.registry_container.name}
    loglevel: info
  delete:
    enabled: true
http:
  addr: 0.0.0.0:5000
EOF
cat <<EOF > /var/lib/registry/compose.yaml
services:
  registry:
    restart: always
    image: registry:2
    ports:
      - 5000:5000
    volumes:
      - .:/etc/docker/registry
EOF
cat <<EOF > /var/lib/registry-for-push/compose.yaml
services:
  registry:
    restart: always
    image: registry:2
    ports:
      - 5001:5000
    volumes:
      - .:/etc/docker/registry
EOF
cat <<EOF > /etc/systemd/system/registry.service
[Unit]
Description=Docker Registry
After=docker.service

[Service]
Type=simple
WorkingDirectory=/var/lib/registry
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
cat <<EOF > /etc/systemd/system/registry-for-push.service
[Unit]
Description=Docker Registry for Push
After=docker.service

[Service]
Type=simple
WorkingDirectory=/var/lib/registry-for-push
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable registry && systemctl start registry
systemctl enable registry-for-push && systemctl start registry-for-push
EOS
}

resource "openstack_networking_floatingip_associate_v2" "registry_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.registry_fip.address
  port_id     = openstack_networking_port_v2.registry_port.id
}

resource "openstack_objectstorage_container_v1" "registry_container" {
  region = "RegionOne"
  name   = "${var.environment_name}-registry"
}
