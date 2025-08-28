resource "openstack_networking_secgroup_v2" "comfyui_sg" {
  name        = "${var.environment_name}-comfyui-sg-${var.resource_suffix}"
  description = "${var.environment_name}-comfyui-sg-${var.resource_suffix}"
}

resource "openstack_networking_secgroup_rule_v2" "comfyui_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8188
  port_range_max    = 8188
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.comfyui_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "comfyui_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.comfyui_sg.id
}

resource "openstack_networking_port_v2" "comfyui_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.comfyui_sg.id]
}

resource "openstack_compute_instance_v2" "comfyui_instance" {
  name      = "${var.environment_name}-comfyui-${var.resource_suffix}"
  flavor_id = var.flavor_id
  key_pair  = var.key_pair_name
  image_id  = var.image_id
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  network {
    port = openstack_networking_port_v2.comfyui_port.id
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# limit gpu power usage
cat <<EOF > /etc/rc.local
#!/bin/sh
nvidia-smi -pl ${var.gpu_power_limit}
EOF
chmod +x /etc/rc.local
/etc/rc.local

# mount nfs mount point
apt-get update && apt-get install -y nfs-common

share_point=/share/comfyui
mount_point=/home/ubuntu/comfy
mkdir -p $${mount_point}
echo "aimodel-nfs.home.dynamis.bbrfkr.net:$${share_point} $${mount_point} nfs defaults 0 0" >> /etc/fstab
mount -a

if [ ! -d /home/ubuntu/comfy/ComfyUI ]; then
  comfy-cli install
fi

cat <<EOF > /etc/systemd/system/comfyui.service
[Unit]
Description=comfyui
After=network.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/bin/bash -c "/home/ubuntu/.pyenv/shims/comfy-cli --skip-prompt install --restore --nvidia && /home/ubuntu/.pyenv/shims/comfy-cli --skip-prompt launch -- --listen 0.0.0.0"
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now comfyui
EOS
}

resource "openstack_networking_floatingip_v2" "comfyui_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "comfyui_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.comfyui_fip.address
  port_id     = openstack_networking_port_v2.comfyui_port.id
}
