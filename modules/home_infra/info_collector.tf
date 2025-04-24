resource "openstack_networking_secgroup_v2" "info_collector_sg" {
  name        = "${var.environment_name}-info-collector-sg"
  description = "${var.environment_name}-info-collector-sg"
}

resource "openstack_networking_secgroup_rule_v2" "info_collector_sg_rule_99" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = var.bastion_sg_id
  security_group_id = openstack_networking_secgroup_v2.info_collector_sg.id
}

resource "openstack_networking_port_v2" "info_collector_port" {
  network_id         = var.network_id
  security_group_ids = [openstack_networking_secgroup_v2.info_collector_sg.id]
}

resource "openstack_compute_instance_v2" "info_collector_instance" {
  name      = "${var.environment_name}-info-collector"
  image_id  = var.info_collector_image_id
  flavor_id = var.info_collector_flavor_id
  key_pair  = var.key_pair_name
  block_device {
    uuid                  = var.info_collector_image_id
    source_type           = "image"
    boot_index            = 0
    destination_type      = "local"
    delete_on_termination = true
  }
  network {
    port = openstack_networking_port_v2.info_collector_port.id
  }
  user_data = <<EOS
#!/bin/sh
apt update
apt install -y build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

git clone https://github.com/pyenv/pyenv.git /root/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /root/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> /root/.bashrc
echo 'eval "$(pyenv init - bash)"' >> /root/.bashrc

export PYENV_ROOT="/root/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

pyenv install 3.10.16
pyenv global 3.10.16
pip install poetry

cd /var/lib
git clone https://github.com/bbrfkr/info-collector
cd info-collector
poetry install

cat <<EOF > /etc/systemd/system/info-collector-redis.service
[Unit]
Description=Info Collector Redis
After=docker.service

[Service]
Type=simple
WorkingDirectory=/var/lib/info-collector
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable info-collector-redis && systemctl start info-collector-redis
cat <<EOF > config.yaml
rss_configs:
  - feed_url: https://news.yahoo.co.jp/rss/topics/top-picks.xml
    webhook_url: ${var.discord_general_news_hook_url}
  - feed_url: https://rss.itmedia.co.jp/rss/2.0/itmedia_all.xml
    webhook_url: ${var.discord_it_news_hook_url}
  - feed_url: https://aws.amazon.com/jp/blogs/news/feed/
    webhook_url: ${var.discord_aws_news_hook_url}
  - feed_url: https://aws.amazon.com/jp/blogs/aws/feed/
    webhook_url: ${var.discord_aws_news_hook_url}
  - feed_url: https://rss.techplay.jp/event/w3c-rss-format/rss.xml
    webhook_url: ${var.discord_it_event_hook_url}
  - feed_url: https://dev.classmethod.jp/feed/
    webhook_url: ${var.discord_developersio_hook_url}
connpass_api_url: "dummy"
connpass_configs: []
EOF

echo "0 * * * * cd /var/lib/info-collector && /root/.pyenv/shims/poetry run python main.py >> /var/log/info-collector.log 2>&1" | crontab -
EOS
}
