resource "openstack_networking_secgroup_v2" "vllm_sg" {
  name        = "${var.environment_name}-vllm-sg-${var.resource_suffix}"
  description = "${var.environment_name}-vllm-sg-${var.resource_suffix}"
}

resource "openstack_networking_secgroup_rule_v2" "vllm_sg_rules" {
  count             = length(var.models_config)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.models_config[count.index].port
  port_range_max    = var.models_config[count.index].port
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vllm_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "vllm_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.vllm_sg.id
}

resource "openstack_networking_port_v2" "vllm_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.vllm_sg.id]
}

resource "openstack_compute_instance_v2" "vllm_instance" {
  name      = "${var.environment_name}-vllm-${var.resource_suffix}"
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
    port = openstack_networking_port_v2.vllm_port.id
  }
  user_data = <<EOD
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive
share_point=/share/huggingface
mount_point=/home/ubuntu/.cache/huggingface

# limit gpu power usage
cat <<EOF > /etc/rc.local
#!/bin/sh
nvidia-smi -pl ${var.gpu_power_limit}
EOF
chmod +x /etc/rc.local
/etc/rc.local

# mount nfs mount point
apt-get update && apt-get install -y nfs-common
mkdir -p $${mount_point}
echo "aimodel-nfs.home.dynamis.bbrfkr.net:$${share_point} $${mount_point} nfs defaults 0 0" >> /etc/fstab
mount -a

# configure vllm services
${join("\n", [for index, config in var.models_config : <<EOS
cat <<EOF > /etc/systemd/system/vllm-${index}.service
[Unit]
Description=vLLM %i
After=network.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
Environment=HF_TOKEN=${var.huggingface_hf_token}
Environment=NCCL_P2P_DISABLE=1
Environment=VLLM_ALLOW_LONG_MAX_MODEL_LEN=1
ExecStart=/bin/bash -c "/home/ubuntu/.pyenv/shims/huggingface-cli scan-cache && /home/ubuntu/.pyenv/shims/vllm serve ${config.model_name} --port ${config.port} ${config.vllm_command_args}"
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
EOS
])}

systemctl daemon-reload
${join("\n", [for index, config in var.models_config : <<EOS
systemctl enable --now vllm-${index}
EOS
])}
EOD
}

resource "openstack_networking_floatingip_v2" "vllm_fip" {
  pool = var.external_subnet_name
}

resource "openstack_networking_floatingip_associate_v2" "vllm_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.vllm_fip.address
  port_id     = openstack_networking_port_v2.vllm_port.id
}
