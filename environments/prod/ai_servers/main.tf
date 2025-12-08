locals {
  completion_gpu_count   = 1
  additional_gpu_count   = 1
  vllm_gpu_count         = 8
  vllm_with_flashinfer_image_id = "8374c2a5-dca6-4992-af53-a38e7af731c5"
  stable_vllm_image_id   = "04036c92-e690-4354-8802-5ad6903f9749"
  comfyui_gpu_count    = 2
  comfyui_image_id     = "ce4d7a80-1176-45b0-b9e5-e322b47e14d7"
  p1_large_id          = "e80fda3b-b3ff-4e95-96af-8513b7a5e469"
  p1_xlarge_id         = "64295d5b-7e47-415c-813c-85dbf35433ac"
  p1_2xlarge_id        = "0b8bc8af-aea4-4dcc-91ae-c15a5558d2be"
  p2_xlarge_id         = "2425aa0b-5890-48df-8be5-e472b09cda69"
  p2_2xlarge_id        = "fdee135d-30af-4cce-aeeb-43306a63ecce"
  p2_4xlarge_id        = "b08b652b-daba-4ec5-83a6-ba91d62b8b25"
  p2_8xlarge_id        = "ad868ad4-124b-44de-a172-50141315d9ea"
  pr2_xlarge_id        = "ad06050a-19dd-4dc5-8aaf-eb4c59ea18b5"
  g1_medium_id = "055dc2d5-ad66-4786-a8b2-003695a62dd5"
  docker_image_id = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
}

module "completion" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p1_2xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "for-completion"
  gpu_count            = local.completion_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  model_name           = "Qwen/Qwen2.5-Coder-1.5B"
  vllm_command_args    = "--served-model-name bbrfkr-completion --gpu-memory-utilization 0.85"
}

module "additional" {
  source               = "../../../modules/vllm-multiple"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p1_2xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "for-additional"
  gpu_count            = local.additional_gpu_count
  gpu_power_limit      = 115
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  models_config = [
    {
      model_name           = "BAAI/bge-m3"
      vllm_command_args = "--served-model-name bbrfkr-embedding --port 8000 --gpu-memory-utilization 0.85 --runner pooling --convert embed --trust-remote-code --max-model-len 819200"
      port = 8000
    }
  ]
}

module "comfyui_2d" {
  source               = "../../../modules/comfyui"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_xlarge_id
  image_id             = local.comfyui_image_id
  resource_suffix      = "2d"
  nfs_share_point      = "/share/comfyui"
  gpu_count            = local.comfyui_gpu_count
  gpu_power_limit      = 150
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "comfyui_3d" {
  source               = "../../../modules/comfyui"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.pr2_xlarge_id
  image_id             = local.comfyui_image_id
  resource_suffix      = "3d"
  nfs_share_point      = "/share/comfyui-3d"
  gpu_count            = local.comfyui_gpu_count
  gpu_power_limit      = 150
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
}

module "vllm_1" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_8xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "1"
  gpu_count            = 8
  gpu_power_limit      = 150
  model_name           = "zai-org/GLM-4.5-Air-FP8"
  vllm_command_args    = "--served-model-name bbrfkr-llm-large --tensor-parallel-size 8 --max-model-len 131072 --max-num-seqs 4 --gpu-memory-utilization 0.85 --tool-call-parser glm45 --reasoning-parser glm45 --enable-auto-tool-choice"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  vllm_use_flashinfer_mxfp4_bf16_moe = 1
}

module "vllm_2" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_2xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "2"
  gpu_count            = 2
  gpu_power_limit      = 150
  model_name           = "openai/gpt-oss-20b"
  vllm_command_args    = "--served-model-name bbrfkr-llm-small --tensor-parallel-size 2 --max-model-len 131072 --max-num-seqs 4 --gpu-memory-utilization 0.85 --async-scheduling"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  vllm_use_flashinfer_mxfp4_bf16_moe = 1
}

module "vllm_3" {
  source               = "../../../modules/vllm"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.p2_4xlarge_id
  image_id             = local.vllm_with_flashinfer_image_id
  resource_suffix      = "3"
  gpu_count            = 4
  gpu_power_limit      = 150
  model_name           = "Qwen/Qwen3-Coder-30B-A3B-Instruct-FP8"
  vllm_command_args    = "--served-model-name bbrfkr-llm-code --tensor-parallel-size 4 --max-model-len 153600 --max-num-seqs 4 --gpu-memory-utilization 0.85 --enable-expert-parallel --tool-call-parser qwen3_coder --enable-auto-tool-choice"
  huggingface_hf_token = base64decode(data.openstack_keymanager_secret_v1.huggingface_hf_token.payload)
  vllm_use_flashinfer_mxfp4_bf16_moe = 1
}

module "litellm" {
  source               = "../../../modules/docker_app_prod"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.g1_medium_id
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
