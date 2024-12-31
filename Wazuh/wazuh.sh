#!/bin/bash

# Function to check if a package is installed
is_package_installed() {
  if dpkg-query -s "$1" &>/dev/null; then
    return 0  # Package is installed
  else
    return 1  # Package is not installed
  fi
}

# Update package lists and install prerequisites
echo "Updating package lists..."
sudo apt-get update -y

# Install Docker if not installed
if ! is_package_installed "docker"; then
  echo "Installing Docker..."
  curl -sSL https://get.docker.com/ | sh
  sudo systemctl start docker
  sudo systemctl enable docker
else
  echo "Docker is already installed. Skipping installation."
fi

# Add user to Docker group to run Docker without sudo
echo "Adding user to Docker group..."
sudo usermod -aG docker $(whoami)
newgrp docker

# Install Docker Compose if not installed
if ! is_package_installed "docker-compose"; then
  echo "Installing Docker Compose..."
  DOCKER_COMPOSE_VERSION="v2.12.2"
  curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose is already installed. Skipping installation."
fi

# Verify installations
echo "Verifying Docker and Docker Compose installations..."
docker --version
docker-compose --version

# Increase vm.max_map_count for Wazuh indexer
echo "Increasing vm.max_map_count..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Clone Wazuh Docker repository
echo "Cloning Wazuh Docker repository..."
git clone https://github.com/wazuh/wazuh-docker.git -b v4.9.2
cd wazuh-docker/single-node

# Generate SSL certificates
echo "Generating SSL certificates..."
docker-compose -f generate-indexer-certs.yml run --rm generator

# Start Wazuh services
echo "Starting Wazuh services..."
docker-compose up -d

# Display status
echo "Wazuh services are starting..."
docker-compose ps

