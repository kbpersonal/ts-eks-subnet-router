#!/bin/sh

# Install Docker Engine 
curl -fsSL https://get.docker.com | sh
systemctl start docker
systemctl enable docker
while ! systemctl is-active --quiet docker; do sleep 2; done

# Allow ubuntu non-root user to create containers
usermod -aG docker ubuntu