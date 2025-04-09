#!/bin/sh

# Get the current kernel version
current_version=$(uname -r | cut -d'-' -f1 | cut -d'.' -f1,2)

# Define the minimum required version
required_version="6.2"

# Detect the default network device. See https://tailscale.com/kb/1320/performance-best-practices#linux-optimizations-for-subnet-routers-and-exit-nodes for more information.
get_default_netdev() {
    # Try ip route show first
    NETDEV=$(ip route show default | awk '/default/ {print $5}' | head -n1)

    # If ip route show didn't work, try using /sys/class/net
    if [ -z "$NETDEV" ]; then
        for dev in /sys/class/net/*; do
            if [ "$dev" != "/sys/class/net/lo" ]; then
                NETDEV=$(basename "$dev")
                break
            fi
        done
    fi

    # If we still don't have a network device, use a fallback
    if [ -z "$NETDEV" ]; then
        echo "eth0"  # Fallback to a common default
    else
        echo "$NETDEV"
    fi
}

# Compare versions
if [ "$(printf '%s\n' "$current_version" "$required_version" | sort -V | tail -n1)" = "$current_version" ]; then
    echo "Kernel version is 6.2 or later. Enabling optimizations..."
    NETDEV=$(get_default_netdev)
    if [ -n "$NETDEV" ]; then
        echo "Using network device: $NETDEV"
        sudo ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off

        # Check if networkd-dispatcher is enabled
        if [ "$(systemctl is-enabled networkd-dispatcher 2>/dev/null)" = "enabled" ]; then
            echo "networkd-dispatcher is enabled. Writing persistent dispatcher script..."

            # Write dispatcher script
            printf '#!/bin/sh\n\nethtool -K %%s rx-udp-gro-forwarding on rx-gro-list off\n' \
              "$(ip -o route get 8.8.8.8 | cut -f 5 -d ' ')" | \
              sudo tee /etc/networkd-dispatcher/routable.d/50-tailscale > /dev/null

            sudo chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

            # Test the script
            echo "Running dispatcher script for verification..."
            sudo /etc/networkd-dispatcher/routable.d/50-tailscale
            if [ $? -ne 0 ]; then
                echo "An error occurred while executing the dispatcher script."
            else
                echo "Dispatcher script ran successfully."
            fi
        else
            echo "networkd-dispatcher is not enabled. Skipping persistent setup."
        fi
    else
        echo "Error: Unable to determine network device. Exiting."
        exit 1
    fi
else
    echo "Kernel version is less than 6.2. Exiting."
    exit 0
fi