locals {
  g1_2xlarge_id = "fac70312-023e-4b61-9492-5434704140ab"
  docker_image_id = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
}

module "litellm" {
  source               = "../../../modules/docker_app_prod"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.g1_2xlarge_id
  image_id             = local.docker_image_id
  app_name             = "litellm"
  docker_app_tcp_ports = ["4000"]
  volume_size = 30
  user_data = <<EOD
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

mkdir -p /var/lib/litellm
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/litellm xfs defaults 0 0' >> /etc/fstab

mount -a

# configure docker mirror
cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://registry.home.dynamis.bbrfkr.net"]
}
EOF
systemctl restart docker

# configure litellm
cat <<EOF > /var/lib/litellm/.env
LITELLM_SALT_KEY="sk-1234"
LITELLM_MASTER_KEY="sk-1234"
EOF
cat <<EOF > /var/lib/litellm/compose.yaml
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-stable
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: "postgresql://llmproxy:insecure@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
    env_file:
      - .env
    depends_on:
      - db
    healthcheck:
      test: [ "CMD-SHELL", "wget --no-verbose --tries=1 http://localhost:4000/health/liveliness || exit 1" ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
  db:
    image: postgres:16
    restart: always
    container_name: litellm_db
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: llmproxy
      POSTGRES_PASSWORD: insecure
    ports:
      - "5432:5432"
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d litellm -U llmproxy"]
      interval: 1s
      timeout: 5s
      retries: 10
EOF

cat <<EOF > /etc/systemd/system/litellm.service
[Unit]
Description=litellm
After=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/lib/litellm
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now litellm
EOD
}
