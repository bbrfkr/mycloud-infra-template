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

resource "openstack_blockstorage_volume_v3" "comfyui_python_volume" {
  name     = "comfyui_python_volume-${var.resource_suffix}"
  size     = 30
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
  block_device {
    uuid                  = openstack_blockstorage_volume_v3.comfyui_python_volume.id
    source_type           = "volume"
    boot_index            = 1
    destination_type      = "volume"
    delete_on_termination = false
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

# gpu fan control
mkdir /var/lib/cron
cat <<'EOF' > /var/lib/cron/gpu_fan_control.sh
#!/bin/sh
gpu_index=$1
fan_index_0=$(expr $gpu_index \* 2)
fan_index_1=$(expr $fan_index_0 + 1)

export DISPLAY=:0
export XAUTHORITY=/var/run/lightdm/root/:0

temp=$(nvidia-settings -q "[gpu:$${gpu_index}]/GPUCoreTemp" | grep Attribute | awk '{print $4}' | awk -F. '{print $1}')
echo "gpu $${gpu_index} temp: $${temp}"

if [ "$${temp}" -gt 55 ]; then
    nvidia-settings -a "[gpu:$${gpu_index}]/GPUFanControlState=1" -a "[fan:$${fan_index_0}]/GPUTargetFanSpeed=100" -a "[fan:$${fan_index_1}]/GPUTargetFanSpeed=100"
elif [ "$${temp}" -gt 45 ]; then
    nvidia-settings -a "[gpu:$${gpu_index}]/GPUFanControlState=1" -a "[fan:$${fan_index_0}]/GPUTargetFanSpeed=60" -a "[fan:$${fan_index_1}]/GPUTargetFanSpeed=60"
elif [ "$${temp}" -gt 40 ]; then
    nvidia-settings -a "[gpu:$${gpu_index}]/GPUFanControlState=1" -a "[fan:$${fan_index_0}]/GPUTargetFanSpeed=30" -a "[fan:$${fan_index_1}]/GPUTargetFanSpeed=30"
else
    nvidia-settings -a "[gpu:$${gpu_index}]/GPUFanControlState=0"
fi
EOF
chmod +x /var/lib/cron/gpu_fan_control.sh
cat <<EOF > /etc/systemd/system/gpu-fan-control@.service
[Unit]
Description=gpu fan control

[Service]
Type=simple
ExecStart=/var/lib/cron/gpu_fan_control.sh %i

[Install]
WantedBy=default.target
EOF
cat <<EOF > /etc/systemd/system/gpu-fan-control@.timer
[Unit]
Description=gpu fan control

[Timer]
OnBootSec=5sec
OnUnitActiveSec=3sec
AccuracySec=1sec
Persistent=true

[Install]
WantedBy=timers.target
EOF
for index in $(seq 0 ${var.gpu_count - 1}); do
  systemctl enable --now gpu-fan-control@$${index}.service
  systemctl enable --now gpu-fan-control@$${index}.timer
done

# mount volume
mkdir -p /python-venv
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /python-venv xfs defaults 0 0' >> /etc/fstab

# mount nfs mount point
apt-get update && apt-get install -y nfs-common

share_point=/share/comfyui
mount_point=/home/ubuntu/comfy
mkdir -p $${mount_point}
echo "aimodel-nfs.home.dynamis.bbrfkr.net:$${share_point} $${mount_point} nfs defaults 0 0" >> /etc/fstab
mount -a

chown ubuntu:ubuntu /python-venv

if [ ! -d "/python-venv/venv" ]; then
  cat <<EOF | sudo -u ubuntu bash -
export PATH=/home/ubuntu/.pyenv/shims:$PATH
python -m venv "/python-venv/venv"
export PATH=/python-venv/venv/bin:$PATH
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu129
pip install comfy-cli
EOF
fi

if [ ! -d /home/ubuntu/comfy/ComfyUI ]; then
  cat <<EOF | sudo -u ubuntu bash -
export PATH=/python-venv/venv/bin:$PATH
comfy-cli install
EOF
fi

cat <<EOF > /etc/systemd/system/comfyui.service
[Unit]
Description=comfyui
After=network.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/bin/bash -c "/python-venv/venv/bin/comfy-cli --skip-prompt install --restore --nvidia && /python-venv/venv/bin/comfy-cli --skip-prompt launch -- --listen 0.0.0.0"
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
