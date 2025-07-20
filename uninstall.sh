#!/bin/bash

# Battery Charge Limiter - Uninstallation Script
# This script removes the battery charge limiter from the system

set -e

echo "🔋 Battery Charge Limiter - Uninstallation Script"
echo "================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run as root. Use sudo."
    exit 1
fi

# Define paths
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"
CONFIG_PATH="/etc"

print_status "Uninstalling battery charge limiter..."

# Stop and disable service
print_status "Stopping bcl service..."
if systemctl is-active --quiet bcl.service; then
    if ! systemctl stop bcl.service; then
        print_warning "Failed to stop bcl.service, continuing anyway"
    else
        print_success "Service stopped"
    fi
else
    print_status "Service is not running"
fi

print_status "Disabling bcl service..."
if systemctl is-enabled --quiet bcl.service 2>/dev/null; then
    if ! systemctl disable bcl.service; then
        print_warning "Failed to disable bcl.service, continuing anyway"
    else
        print_success "Service disabled"
    fi
else
    print_status "Service is not enabled"
fi

# Remove files
print_status "Removing installed files..."

if [ -f "$BIN_PATH/bcl" ]; then
    rm -f "$BIN_PATH/bcl"
    print_success "Removed $BIN_PATH/bcl"
else
    print_status "$BIN_PATH/bcl not found"
fi

if [ -f "$BIN_PATH/bcl-apply" ]; then
    rm -f "$BIN_PATH/bcl-apply"
    print_success "Removed $BIN_PATH/bcl-apply"
else
    print_status "$BIN_PATH/bcl-apply not found"
fi

if [ -f "$SERVICE_PATH/bcl.service" ]; then
    rm -f "$SERVICE_PATH/bcl.service"
    print_success "Removed $SERVICE_PATH/bcl.service"
else
    print_status "$SERVICE_PATH/bcl.service not found"
fi

# Ask about configuration file
if [ -f "$CONFIG_PATH/bcl.conf" ]; then
    echo ""
    print_warning "Configuration file found at $CONFIG_PATH/bcl.conf"
    read -p "Do you want to remove it? [y/N]: " response
    case $response in
        [yY][eE][sS]|[yY])
            rm -f "$CONFIG_PATH/bcl.conf"
            print_success "Removed $CONFIG_PATH/bcl.conf"
            ;;
        *)
            print_status "Keeping configuration file"
            ;;
    esac
else
    print_status "Configuration file not found"
fi

# Reload systemd
print_status "Reloading systemd daemon..."
systemctl daemon-reload

echo ""
print_success "Uninstallation completed successfully!"

# Verify removal
if ! systemctl list-unit-files | grep -q bcl.service; then
    print_success "Service completely removed from systemd"
else
    print_warning "Service may still be visible in systemd"
fi

echo ""
print_status "Battery charge limiter has been removed from your system"