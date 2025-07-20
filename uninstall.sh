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

# Check if running as regular user
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root. Run as regular user."
    exit 1
fi

print_status "Uninstalling Battery Charge Limiter..."

# Stop and disable systemd services
print_status "Stopping and disabling systemd services..."

# User service (new)
if systemctl --user is-active --quiet battery-charge-limiter.service 2>/dev/null; then
    systemctl --user stop battery-charge-limiter.service
    print_success "Stopped user service"
fi

if systemctl --user is-enabled --quiet battery-charge-limiter.service 2>/dev/null; then
    systemctl --user disable battery-charge-limiter.service
    print_success "Disabled user service"
fi

# Legacy system service (old)
if systemctl is-active --quiet bcl.service 2>/dev/null; then
    sudo systemctl stop bcl.service
    print_success "Stopped legacy system service"
fi

if systemctl is-enabled --quiet bcl.service 2>/dev/null; then
    sudo systemctl disable bcl.service
    print_success "Disabled legacy system service"
fi

# Remove installed files
print_status "Removing installed files..."

# Remove Python package
if command -v pipx &> /dev/null; then
    if pipx list | grep -q battery-charge-limiter; then
        pipx uninstall battery-charge-limiter
        print_success "Removed package via pipx"
    fi
else
    # Remove from user installation
    if pip show battery-charge-limiter &> /dev/null; then
        pip uninstall -y battery-charge-limiter
        print_success "Removed package via pip"
    fi
    
    # Remove virtual environment
    VENV_DIR="$HOME/.local/share/battery-limiter-venv"
    if [ -d "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
        print_success "Removed virtual environment"
    fi
fi

# Remove wrapper scripts
for script in battery-limiter battery-limiter-gui; do
    if [ -f "$HOME/.local/bin/$script" ]; then
        rm -f "$HOME/.local/bin/$script"
        print_success "Removed $HOME/.local/bin/$script"
    fi
done

# Remove desktop entry
DESKTOP_FILE="$HOME/.local/share/applications/battery-charge-limiter.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    rm -f "$DESKTOP_FILE"
    print_success "Removed desktop entry"
fi

# Remove systemd service files
USER_SERVICE="$HOME/.config/systemd/user/battery-charge-limiter.service"
if [ -f "$USER_SERVICE" ]; then
    rm -f "$USER_SERVICE"
    systemctl --user daemon-reload
    print_success "Removed user systemd service"
fi

# Remove legacy files (with sudo)
print_status "Removing legacy system files..."

LEGACY_FILES=(
    "/usr/local/bin/bcl"
    "/usr/local/bin/bcl-apply"
    "/etc/systemd/system/bcl.service"
)

for file in "${LEGACY_FILES[@]}"; do
    if [ -f "$file" ]; then
        sudo rm -f "$file"
        print_success "Removed legacy file: $file"
    fi
done

# Ask about configuration file
if [ -f "/etc/bcl.conf" ]; then
    echo ""
    print_warning "Legacy configuration file found at /etc/bcl.conf"
    read -p "Do you want to remove it? [y/N]: " response
    case $response in
        [yY][eE][sS]|[yY])
            sudo rm -f "/etc/bcl.conf"
            print_success "Removed /etc/bcl.conf"
            ;;
        *)
            print_status "Keeping configuration file"
            ;;
    esac
fi

# Reload systemd
sudo systemctl daemon-reload 2>/dev/null || true

echo ""
print_success "Uninstallation completed successfully!"
echo ""
print_status "Battery Charge Limiter has been completely removed from your system"