locals {
  g1_medium_id = "055dc2d5-ad66-4786-a8b2-003695a62dd5"
  docker_image_id = "2bb089f3-e64d-475a-8f7e-75842c9d11a7"
  photo_prism_site_url = "https://photo-prism.external.dynamis.bbrfkr.net/"
}

module "photo_prism" {
  source               = "../../../modules/docker_app_prod"
  environment_name     = data.terraform_remote_state.common.outputs.environment_name
  project_id           = data.terraform_remote_state.global_common.outputs.project_id
  network_id           = data.terraform_remote_state.networking.outputs.all.network_id
  bastion_sg_id        = data.terraform_remote_state.bastion.outputs.all.bastion_sg_id
  external_subnet_name = data.terraform_remote_state.global_common.outputs.external_subnet_name
  flavor_id            = local.g1_medium_id
  image_id             = local.docker_image_id
  app_name             = "photo-prism"
  docker_app_tcp_ports = ["2342"]
  volume_size = 60
  user_data = <<EOD
#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# mount nfs share and volume
apt-get update && apt-get install -y nfs-common

share_point=/share/comfyui
mount_point=/var/lib/comfyui
mkdir -p $${mount_point}
echo "aimodel-nfs.home.dynamis.bbrfkr.net:$${share_point} $${mount_point} nfs defaults 0 0" >> /etc/fstab

mkdir -p /var/lib/photo_prism
lsblk -f /dev/vdb | grep xfs > /dev/null
if [ $? -ne 0 ] ; then
    mkfs -t xfs /dev/vdb
fi
echo '/dev/vdb /var/lib/photo_prism xfs defaults 0 0' >> /etc/fstab

mount -a

# configure photo prism
mkdir -p /var/lib/photo_prism
cat <<EOF > /var/lib/photo_prism/compose.yaml
services:
  photoprism:
    image: photoprism/photoprism:latest
    stop_grace_period: 10s
    depends_on:
      - mariadb
    security_opt:
      - seccomp:unconfined
      - apparmor:unconfined
    ports:
      - "2342:2342"
    environment:
      PHOTOPRISM_ADMIN_USER: "admin"                 
      PHOTOPRISM_ADMIN_PASSWORD: "insecure"          
      PHOTOPRISM_AUTH_MODE: "password"               
      PHOTOPRISM_SITE_URL: "${local.photo_prism_site_url}"  
      PHOTOPRISM_DISABLE_TLS: "true"                
      PHOTOPRISM_DEFAULT_TLS: "false"                 
      PHOTOPRISM_ORIGINALS_LIMIT: 5000               
      PHOTOPRISM_HTTP_COMPRESSION: "gzip"            
      PHOTOPRISM_LOG_LEVEL: "info"                   
      PHOTOPRISM_READONLY: "false"                   
      PHOTOPRISM_EXPERIMENTAL: "false"               
      PHOTOPRISM_DISABLE_CHOWN: "false"              
      PHOTOPRISM_DISABLE_WEBDAV: "false"             
      PHOTOPRISM_DISABLE_SETTINGS: "false"           
      PHOTOPRISM_DISABLE_TENSORFLOW: "false"         
      PHOTOPRISM_DISABLE_FACES: "false"              
      PHOTOPRISM_DISABLE_CLASSIFICATION: "false"     
      PHOTOPRISM_DISABLE_VECTORS: "false"            
      PHOTOPRISM_DISABLE_RAW: "false"                
      PHOTOPRISM_RAW_PRESETS: "false"                
      PHOTOPRISM_SIDECAR_YAML: "true"                
      PHOTOPRISM_BACKUP_ALBUMS: "true"               
      PHOTOPRISM_BACKUP_DATABASE: "true"             
      PHOTOPRISM_BACKUP_SCHEDULE: "daily"            
      PHOTOPRISM_INDEX_SCHEDULE: ""                  
      PHOTOPRISM_AUTO_INDEX: 120                     
      PHOTOPRISM_AUTO_IMPORT: 150                    
      PHOTOPRISM_DETECT_NSFW: "false"                
      PHOTOPRISM_UPLOAD_NSFW: "true"                 
      PHOTOPRISM_DATABASE_DRIVER: "mysql"            
      PHOTOPRISM_DATABASE_SERVER: "mariadb:3306"     
      PHOTOPRISM_DATABASE_NAME: "photoprism"         
      PHOTOPRISM_DATABASE_USER: "photoprism"         
      PHOTOPRISM_DATABASE_PASSWORD: "insecure"       
      PHOTOPRISM_SITE_CAPTION: "AI-Powered Photos App"
      PHOTOPRISM_SITE_DESCRIPTION: ""                
      PHOTOPRISM_SITE_AUTHOR: ""                     
    working_dir: "/photoprism" 
    volumes:
      - "/var/lib/comfyui/ComfyUI/output:/photoprism/originals/comfyui"
      - "./storage:/photoprism/storage"
  mariadb:
    image: mariadb:11
    restart: unless-stopped
    stop_grace_period: 5s
    security_opt: 
      - seccomp:unconfined
      - apparmor:unconfined
    command: --innodb-buffer-pool-size=512M --transaction-isolation=READ-COMMITTED --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max-connections=512 --innodb-rollback-on-timeout=OFF --innodb-lock-wait-timeout=120
    volumes:
      - "./database:/var/lib/mysql" 
    environment:
      MARIADB_AUTO_UPGRADE: "1"
      MARIADB_INITDB_SKIP_TZINFO: "1"
      MARIADB_DATABASE: "photoprism"
      MARIADB_USER: "photoprism"
      MARIADB_PASSWORD: "insecure"
      MARIADB_ROOT_PASSWORD: "insecure"
  watchtower:
    restart: unless-stopped
    image: containrrr/watchtower
    profiles: ["update"]
    environment:
      WATCHTOWER_CLEANUP: "true"
      WATCHTOWER_POLL_INTERVAL: 7200 
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "~/.docker/config.json:/config.json" 
EOF
cat <<EOF > /etc/systemd/system/photo_prism.service
[Unit]
Description=photo prism
After=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/lib/photo_prism
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now photo_prism

(crontab -l; echo "*/5 * * * * cd /var/lib/photo_prism && /usr/bin/docker compose exec -T photoprism photoprism index") | crontab -
EOD
}

