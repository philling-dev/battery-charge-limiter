
#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run as root. Use sudo."
    exit 1
fi

# Paths to files installed by the project
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"
CONFIG_PATH="/etc"

echo "Stopping and disabling the bcl service..."
systemctl stop bcl.service
systemctl disable bcl.service

echo "Removing installed files..."
rm -f "$BIN_PATH/bcl"
rm -f "$BIN_PATH/bcl-apply"
rm -f "$SERVICE_PATH/bcl.service"
rm -f "$CONFIG_PATH/bcl.conf"

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Uninstallation complete!"
