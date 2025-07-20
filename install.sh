#!/bin/bash

# Battery Charge Limiter - Installation Script
# This script installs the battery charge limiter system service

set -e

echo "🔋 Battery Charge Limiter - Installation Script"
echo "==============================================="

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

# Verify we're in the correct directory
if [ ! -f "bcl.py" ] || [ ! -f "bcl-apply" ] || [ ! -f "bcl.service" ] || [ ! -f "bcl.conf" ]; then
    print_error "Required files not found. Make sure you're in the battery-charge-limiter directory."
    print_error "Expected files: bcl.py, bcl-apply, bcl.service, bcl.conf"
    exit 1
fi

# Define paths
SOURCE_DIR="$(pwd)"
BIN_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system"
CONFIG_PATH="/etc"

print_status "Installing battery charge limiter..."

# Create directories if they don't exist
mkdir -p "$BIN_PATH"
mkdir -p "$SERVICE_PATH"

# Copy files and verify success
print_status "Copying files to system directories..."

if ! cp "$SOURCE_DIR/bcl.py" "$BIN_PATH/bcl"; then
    print_error "Failed to copy bcl.py to $BIN_PATH/bcl"
    exit 1
fi

if ! cp "$SOURCE_DIR/bcl-apply" "$BIN_PATH/bcl-apply"; then
    print_error "Failed to copy bcl-apply to $BIN_PATH/bcl-apply"
    exit 1
fi

if ! cp "$SOURCE_DIR/bcl.service" "$SERVICE_PATH/bcl.service"; then
    print_error "Failed to copy bcl.service to $SERVICE_PATH/bcl.service"
    exit 1
fi

print_success "Files copied successfully"

# Create configuration file if it doesn't exist
if [ ! -f "$CONFIG_PATH/bcl.conf" ]; then
    if ! cp "$SOURCE_DIR/bcl.conf" "$CONFIG_PATH/bcl.conf"; then
        print_error "Failed to copy bcl.conf to $CONFIG_PATH/bcl.conf"
        exit 1
    fi
    print_success "Configuration file created at $CONFIG_PATH/bcl.conf with default 80% limit"
else
    print_warning "Configuration file already exists at $CONFIG_PATH/bcl.conf"
fi

# Set executable permissions
print_status "Setting executable permissions..."
chmod +x "$BIN_PATH/bcl"
chmod +x "$BIN_PATH/bcl-apply"

# Reload systemd and enable service
print_status "Configuring systemd service..."
systemctl daemon-reload

print_status "Enabling bcl service to start at boot..."
if ! systemctl enable bcl.service; then
    print_error "Failed to enable bcl.service"
    exit 1
fi

print_status "Starting bcl service..."
if ! systemctl start bcl.service; then
    print_error "Failed to start bcl.service"
    print_error "Check service status with: systemctl status bcl.service"
    exit 1
fi

# Verify installation
print_status "Verifying installation..."

if systemctl is-active --quiet bcl.service; then
    print_success "Service is running successfully"
else
    print_warning "Service is not running. Check status with: systemctl status bcl.service"
fi

if [ -f "$CONFIG_PATH/bcl.conf" ]; then
    LIMIT=$(cat "$CONFIG_PATH/bcl.conf" 2>/dev/null || echo "unknown")
    print_success "Configuration file exists with limit: ${LIMIT}%"
fi

echo ""
print_success "Installation completed successfully!"
echo ""
echo "📖 Usage:"
echo "  • Check status: sudo systemctl status bcl.service"
echo "  • Change limit: sudo nano /etc/bcl.conf"
echo "  • Restart service: sudo systemctl restart bcl.service"
echo "  • Apply immediately: sudo bcl-apply"
echo ""
print_warning "Note: Your laptop must support battery charge limiting via sysfs"
print_warning "Compatible with most ASUS, Lenovo, and Dell laptops"