#!/bin/bash

echo 'Pleas set all the variables for the .env file'

read -r -p "Domain name             --> " SITE
read -r -p "Time/Zone               --> " TIMEZONE
read -r -p "CloudFlare DDNS API Key --> " DNSAPI

# Add variables for the docker images
USER="${SUDO_USER:-$USER}"
PUID="$(id -u "${SUDO_USER:-$USER}")"
PGID="$(id -g "${SUDO_USER:-$USER}")"
ROOT_PASSWORD="$(gpg --gen-random --armor 1 20)"
MYSQL_DATABASE="$(gpg --gen-random --armor 1 6)"
MYSQL_USER="$(gpg --gen-random --armor 1 6)"
MYSQL_PASSWORD="$(gpg --gen-random --armor 1 14)"

#Create directories
mkdir -p /home/"${SUDO_USER:-$USER}"/docker/{portainer-data,homer,prometheus,qbit,Downloads,Jackett,Radarr,Sonarr,filebrowser,code,wireguard,Matomo}
mkdir -p /home/"${SUDO_USER:-$USER}"/docker/nginx/{mysql,data,letsencrypt}
mkdir -p /home/"${SUDO_USER:-$USER}"/docker/Video/{Filmovi,Crtani,Anime,Serije,Anime-serije}

# Allow ports
ufw allow 22    #SSH
ufw allow 39001 #Portainer
ufw allow 39002 #Nginx
ufw allow 39003 #Homer
ufw allow 39004 #Grafana
ufw allow 39005 #Prometheus
ufw allow 39006 #Speedtest
ufw allow 39007 #Qbittorrent
ufw allow 39008 #Jackett
ufw allow 39009 #Radarr
ufw allow 39010 #Sonarr
ufw allow 39011 #Filebrowser
ufw allow 39012 #VSCode
ufw allow 39013 #Matomo
ufw allow 51820 #Wireguard

# Create .env file
cat <<EOF > /home/"${SUDO_USER:-$USER}"/docker/.env
USER="${USER}"
SITE="${SITE}"
TIMEZONE="${TIMEZONE}"
PUID="${PUID}"
PGID="${PGID}"
DNSAPI="${DNSAPI}"
ROOT_PASSWORD="${ROOT_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_USER="${MYSQL_USER}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
EOF

# Create Prometheus config file
cat <<EOF > /home/"${SUDO_USER:-$USER}"/docker/prometheus/prometheus.yml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  # external_labels:
  #  monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'
    # Override the global default and scrape targets from this job every 5 seconds.
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

  # Example job for node_exporter
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']

  # Example job for cadvisor
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

#Create network for the containers
docker network create proxy

# Run Docker images
cp ./docker_config/homer_config.yml /home/"${SUDO_USER:-$USER}"/docker/homer/config.yml
cp ./docker_config/docker-compose.yml /home/"${SUDO_USER:-$USER}"/docker/docker-compose.yml
#setfacl -m "u:root:rw" /home/"${SUDO_USER:-$USER}"/docker/.env
docker-compose -f /home/"${SUDO_USER:-$USER}"/docker/docker-compose.yml --env-file /home/"${SUDO_USER:-$USER}"/docker/.env up -d

# Clean up
rm -rf /home/"${SUDO_USER:-$USER}"/.gnupg

cat <<EOF >> /etc/cron.d/crontask
25 5 * * * root    docker system prune -a -f
EOF
crontab -u "${SUDO_USER:-$USER}" /etc/cron.d/crontask