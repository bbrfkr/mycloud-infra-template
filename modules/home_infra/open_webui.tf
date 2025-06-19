resource "openstack_networking_secgroup_v2" "open_webui_sg" {
  name        = "${var.environment_name}-open-webui-sg"
  description = "${var.environment_name}-open-webui-sg"
}

resource "openstack_networking_secgroup_rule_v2" "open_webui_sg_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.open_webui_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "open_webui_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.open_webui_sg.id
}

resource "openstack_networking_floatingip_v2" "open_webui_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_port_v2" "open_webui_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.open_webui_sg.id]
}

resource "openstack_blockstorage_volume_v3" "open_webui_data_volume" {
  name = "open-webui-data-volume"
  size = 30
}

resource "openstack_compute_instance_v2" "open_webui_instance" {
  name      = "${var.environment_name}-open-webui"
  image_id  = var.open_webui_image_id
  flavor_id = var.open_webui_flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.open_webui_image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.open_webui_data_volume.id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
  }
  network {
    port = openstack_networking_port_v2.open_webui_port.id
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# configure docker mirror
cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://registry.home.dynamis.bbrfkr.net"]
}
EOF
systemctl restart docker

# mount volume
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
mkdir -p /var/lib/open-webui
echo '/dev/vdb /var/lib/open-webui xfs defaults 0 0' >> /etc/fstab
mount -a

cat <<EOF > /var/lib/open-webui/compose.yaml
services:
  open_webui:
    restart: always
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - 8080:8080
    volumes:
      - /var/lib/open-webui/data:/app/backend/data
EOF
cat <<EOF > /etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUi
After=docker.service

[Service]
Type=simple
WorkingDirectory=/var/lib/open-webui
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now open-webui
EOS
}

resource "openstack_networking_floatingip_associate_v2" "open_webui_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.open_webui_fip.address
  port_id     = openstack_networking_port_v2.open_webui_port.id
}
