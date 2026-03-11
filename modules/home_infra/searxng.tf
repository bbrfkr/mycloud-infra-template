# resource "openstack_networking_secgroup_v2" "searxng_sg" {
#   name        = "${var.environment_name}-searxng-sg"
#   description = "${var.environment_name}-searxng-sg"
# }

# resource "openstack_networking_secgroup_rule_v2" "searxng_sg_rule_2" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 8080
#   port_range_max    = 8080
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = openstack_networking_secgroup_v2.searxng_sg.id
# }

# resource "openstack_networking_secgroup_rule_v2" "searxng_sg_rule_3" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 3000
#   port_range_max    = 3000
#   remote_ip_prefix  = "0.0.0.0/0"
#   security_group_id = openstack_networking_secgroup_v2.searxng_sg.id
# }

# resource "openstack_networking_secgroup_rule_v2" "searxng_sg_rule_99" {
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   remote_group_id   = var.bastion_sg_id
#   security_group_id = openstack_networking_secgroup_v2.searxng_sg.id
# }

# resource "openstack_networking_floatingip_v2" "searxng_fip" {
#   pool = var.external_subnet_name
# }

# resource "openstack_networking_port_v2" "searxng_port" {
#   network_id         = var.network_id
#   security_group_ids = [openstack_networking_secgroup_v2.searxng_sg.id]
# }

# resource "openstack_blockstorage_volume_v3" "searxng_data_volume" {
#   name = "searxng-data-volume"
#   size = 30
# }

# resource "openstack_compute_instance_v2" "searxng_instance" {
#   name      = "${var.environment_name}-searxng"
#   image_id  = var.searxng_image_id
#   flavor_id = var.searxng_flavor_id
#   key_pair  = var.key_pair_name
#   block_device {
#     uuid                  = var.searxng_image_id
#     source_type           = "image"
#     boot_index            = 0
#     destination_type      = "local"
#     delete_on_termination = true
#   }
#   block_device {
#     uuid                  = openstack_blockstorage_volume_v3.searxng_data_volume.id
#     source_type           = "volume"
#     boot_index            = 1
#     destination_type      = "volume"
#     delete_on_termination = false
#   }
#   network {
#     port = openstack_networking_port_v2.searxng_port.id
#   }
#   user_data = <<EOS
# #!/bin/sh
# export DEBIAN_FRONTEND=noninteractive

# # configure docker mirror
# cat <<EOF > /etc/docker/daemon.json
# {
#   "registry-mirrors": ["https://registry.home.dynamis.bbrfkr.net"]
# }
# EOF
# systemctl restart docker

# # mount volume
# lsblk -f /dev/vdb | grep xfs > /dev/null
# if [ $? -ne 0 ] ; then
#     mkfs -t xfs /dev/vdb
# fi
# mkdir -p /var/lib/searxng
# echo '/dev/vdb /var/lib/searxng xfs defaults 0 0' >> /etc/fstab
# mount -a

# cd /var/lib/searxng
# if [ ! -d searxng-docker ] ; then
#   git clone https://github.com/bbrfkr/searxng-docker
#   cd searxng-docker
#   cat <<EOF > .env
# SEARXNG_VALKEY_URL=valkey://cache:6379/0
# GRANIAN_WORKERS=${var.searxng_workers}
# GRANIAN_THREADS=${var.searxng_threads}
# EOF
# fi

# cat <<EOF > /etc/systemd/system/searxng.service
# [Unit]
# Description=Searxng
# After=docker.service

# [Service]
# Type=simple
# WorkingDirectory=/var/lib/searxng/searxng-docker
# ExecStart=/usr/bin/docker compose up
# ExecStop=/usr/bin/docker compose down
# Restart=yes

# [Install]
# WantedBy=multi-user.target
# EOF
# systemctl daemon-reload
# systemctl enable --now searxng
# EOS
# }

# resource "openstack_networking_floatingip_associate_v2" "searxng_fip_associate" {
#   floating_ip = openstack_networking_floatingip_v2.searxng_fip.address
#   port_id     = openstack_networking_port_v2.searxng_port.id
# }

# resource "openstack_dns_recordset_v2" "searxng_searxng_rs" {
#   zone_id     = openstack_dns_zone_v2.zone.id
#   name        = "searxng.${openstack_dns_zone_v2.zone.name}"
#   description = "for searxng"
#   ttl         = 600
#   type        = "CNAME"
#   records     = ["prd-router.dynamis.bbrfkr.net."]
# }