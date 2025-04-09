#!/bin/sh

echo "Set required IP forwarding kernel values"

if [ -d /etc/sysctl.d ]; then
    echo "Using /etc/sysctl.d/99-tailscale.conf"
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
    sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
else
    echo "Using /etc/sysctl.conf"
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p /etc/sysctl.conf
fi

# Check if firewalld is running and active
if command -v firewall-cmd >/dev/null 2>&1 && sudo systemctl is-active --quiet firewalld; then
    echo "firewalld is active — enabling masquerading"
    sudo firewall-cmd --permanent --add-masquerade
    sudo firewall-cmd --reload
else
    echo "firewalld is not active — skipping masquerade rule"
fi
