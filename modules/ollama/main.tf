resource "openstack_networking_secgroup_v2" "ollama_sg" {
  name        = "${var.environment_name}-ollama-sg-${var.resource_suffix}"
  description = "${var.environment_name}-ollama-sg-${var.resource_suffix}"
}

resource "openstack_networking_secgroup_rule_v2" "ollama_sg_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8000
  port_range_max    = 8000
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ollama_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "ollama_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.ollama_sg.id
}

resource "openstack_networking_port_v2" "ollama_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.ollama_sg.id]
}

resource "openstack_compute_instance_v2" "ollama_instance" {
  name      = "${var.environment_name}-ollama-${var.resource_suffix}"
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
    port = openstack_networking_port_v2.ollama_port.id
  }
  user_data = <<EOS
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

share_point=/share/models
mount_point=/usr/share/ollama/.ollama/models

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

# mount nfs mount point
apt-get update && apt-get install -y nfs-common
mkdir -p $${mount_point}
echo "aimodel-nfs.home.dynamis.bbrfkr.net:$${share_point} $${mount_point} nfs defaults 0 0" >> /etc/fstab
mount -a

# configure registry mirrorsAdd commentMore actions
cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://registry.home.dynamis.bbrfkr.net"]
}
EOF
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# configure ollama
mkdir -p /var/lib/ollama
cat <<EOF > /var/lib/ollama/compose.yaml
services:
  ollama:
    restart: always
    image: ollama/ollama
    ports:
      - 8000:11434
    volumes:
      - $${mount_point}:/root/.ollama/models
    environment:
      - "OLLAMA_FLASH_ATTENTION=1"
      - "OLLAMA_KV_CACHE_TYPE=q8_0"
      - "OLLAMA_KEEP_ALIVE=-1"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF
cat <<EOF > /etc/systemd/system/ollama.service
[Unit]
Description=Ollama
After=docker.service

[Service]
Type=simple
WorkingDirectory=/var/lib/ollama
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now ollama
EOS
}

resource "openstack_networking_floatingip_v2" "ollama_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "ollama_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.ollama_fip.address
  port_id     = openstack_networking_port_v2.ollama_port.id
}
