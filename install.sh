#!/bin/bash

# Battery Charge Limiter - Installation Script
# This script installs the battery charge limiter system with GUI support

set -e

echo "🔋 Battery Charge Limiter - Installation Script"
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

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    print_error "Cannot detect Linux distribution"
    exit 1
fi

print_status "Detected distribution: $DISTRO"

# Install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    case $DISTRO in
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y python3-pip python3-venv python3-pyqt6
            ;;
        "fedora")
            sudo dnf install -y python3-pip python3-virtualenv python3-qt6
            ;;
        "arch"|"manjaro")
            sudo pacman -S --noconfirm python-pip python-pyqt6
            ;;
        "opensuse"|"opensuse-leap"|"opensuse-tumbleweed")
            sudo zypper install -y python3-pip python3-qt6
            ;;
        *)
            print_warning "Distribution not explicitly supported. Trying generic installation..."
            print_status "Please install python3-pip and python3-pyqt6 manually if this fails"
            ;;
    esac
    
    print_success "System dependencies installed"
}

# Check battery support
check_battery_support() {
    print_status "Checking battery charge limiting support..."
    
    BATTERY_FOUND=false
    for bat_dir in /sys/class/power_supply/BAT*; do
        if [ -d "$bat_dir" ]; then
            if [ -f "$bat_dir/charge_control_end_threshold" ] || [ -f "$bat_dir/charge_stop_threshold" ]; then
                BATTERY_FOUND=true
                print_success "Battery charge limiting is supported"
                break
            fi
        fi
    done
    
    if [ "$BATTERY_FOUND" = false ]; then
        print_warning "Battery charge limiting may not be supported on this system"
        print_warning "The application will still install but may not function"
    fi
}

# Install Python package
install_python_package() {
    print_status "Installing Python package..."
    
    # Check for PEP 668 externally-managed environment
    PEP668_ERROR=false
    
    # Try pipx first if available
    if command -v pipx &> /dev/null; then
        print_status "Using pipx for installation..."
        if [ -f "pyproject.toml" ] && [ -d "src/battery_limiter" ]; then
            pipx install -e .
        else
            pipx install battery-charge-limiter
        fi
        print_success "Python package installed via pipx"
        return
    fi
    
    # Check if we're in the source directory
    if [ -f "pyproject.toml" ] && [ -d "src/battery_limiter" ]; then
        print_status "Installing from source directory..."
        if ! pip install --user -e . 2>/tmp/pip_error.log; then
            if grep -q "externally-managed-environment" /tmp/pip_error.log; then
                PEP668_ERROR=true
            else
                print_error "Installation failed. Check /tmp/pip_error.log"
                exit 1
            fi
        fi
    else
        print_status "Installing from PyPI..."
        if ! pip install --user battery-charge-limiter 2>/tmp/pip_error.log; then
            if grep -q "externally-managed-environment" /tmp/pip_error.log; then
                PEP668_ERROR=true
            else
                print_error "Installation failed. Check /tmp/pip_error.log"
                exit 1
            fi
        fi
    fi
    
    # Handle PEP 668 error by creating a virtual environment
    if [ "$PEP668_ERROR" = true ]; then
        print_warning "PEP 668 externally-managed-environment detected"
        print_status "Creating virtual environment for installation..."
        
        VENV_DIR="$HOME/.local/share/battery-limiter-venv"
        python3 -m venv "$VENV_DIR"
        
        # Install PyQt6 in virtual environment first
        print_status "Installing PyQt6 in virtual environment..."
        "$VENV_DIR/bin/pip" install PyQt6
        
        if [ -f "pyproject.toml" ] && [ -d "src/battery_limiter" ]; then
            print_status "Installing from source in virtual environment..."
            "$VENV_DIR/bin/pip" install -e .
        else
            print_status "Installing from PyPI in virtual environment..."
            "$VENV_DIR/bin/pip" install battery-charge-limiter
        fi
        
        # Create wrapper scripts in ~/.local/bin
        mkdir -p "$HOME/.local/bin"
        
        cat > "$HOME/.local/bin/battery-limiter" << EOF
#!/bin/bash
exec "$VENV_DIR/bin/python" -m battery_limiter.cli "\$@"
EOF
        
        # Detect Python version in venv
        PYTHON_VER=$(ls "$VENV_DIR/lib/" | grep "python" | head -n1)
        
        cat > "$HOME/.local/bin/battery-limiter-gui" << EOF
#!/bin/bash
VENV_DIR="$VENV_DIR"
PYTHON_VER="$PYTHON_VER"

# Set Qt environment variables with correct paths
export QT_QPA_PLATFORM_PLUGIN_PATH="\$VENV_DIR/lib/\$PYTHON_VER/site-packages/PyQt6/Qt6/plugins"
export LD_LIBRARY_PATH="\$VENV_DIR/lib/\$PYTHON_VER/site-packages/PyQt6/Qt6/lib:\$LD_LIBRARY_PATH"

# Fallback to system Qt if virtual env Qt fails
if [ ! -d "\$QT_QPA_PLATFORM_PLUGIN_PATH" ]; then
    unset QT_QPA_PLATFORM_PLUGIN_PATH
    unset LD_LIBRARY_PATH
fi

exec "\$VENV_DIR/bin/python" -m battery_limiter.gui "\$@"
EOF
        
        chmod +x "$HOME/.local/bin/battery-limiter"
        chmod +x "$HOME/.local/bin/battery-limiter-gui"
        
        print_success "Installed in virtual environment with wrapper scripts"
    fi
    
    # Make sure ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_warning "~/.local/bin is not in your PATH"
        print_status "Adding to ~/.bashrc..."
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        print_success "Added ~/.local/bin to PATH in ~/.bashrc"
    fi
    
    print_success "Python package installed"
}

# Create desktop entry
create_desktop_entry() {
    print_status "Creating desktop entry..."
    
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/battery-charge-limiter.desktop" << EOF
[Desktop Entry]
Name=Battery Charge Limiter
GenericName=Power Management
Comment=Control battery charge limit to extend battery lifespan
Exec=$HOME/.local/bin/battery-limiter-gui
Icon=battery
Terminal=false
Type=Application
Categories=Settings;HardwareSettings;System;
Keywords=battery;charge;limit;power;laptop;conservation;threshold;
StartupNotify=true
MimeType=
EOF
    
    print_success "Desktop entry created"
}

# Setup systemd service (optional, backwards compatibility)
setup_systemd_service() {
    print_status "Setting up systemd service (optional for auto-apply)..."
    
    if [ -f "bcl.service" ] && [ -f "bcl.conf" ]; then
        print_status "Installing legacy systemd service..."
        
        SERVICE_DIR="$HOME/.config/systemd/user"
        mkdir -p "$SERVICE_DIR"
        
        # Update service to use new CLI
        sed 's|ExecStart=.*|ExecStart='$HOME'/.local/bin/battery-limiter 80|' bcl.service > "$SERVICE_DIR/battery-charge-limiter.service"
        
        # Copy config if it doesn't exist
        if [ ! -f "/etc/bcl.conf" ]; then
            sudo cp bcl.conf /etc/bcl.conf
            print_success "Configuration file installed"
        fi
        
        # Enable service
        systemctl --user daemon-reload
        systemctl --user enable battery-charge-limiter.service
        print_success "Systemd service setup completed"
    else
        print_status "Systemd service files not found, skipping"
    fi
}

# Show completion message
show_completion() {
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "🎉 Battery Charge Limiter is now installed!"
    echo ""
    echo "📖 Usage:"
    echo "  • GUI Application: battery-limiter-gui (or find 'Battery Charge Limiter' in your applications menu)"
    echo "  • Command Line: battery-limiter <percentage>"
    echo "  • Examples:"
    echo "    - battery-limiter 80    # Set limit to 80%"
    echo "    - battery-limiter --info 60    # Show battery info and set to 60%"
    echo ""
    echo "💡 Tips:"
    echo "  • The GUI provides an easy-to-use interface for non-technical users"
    echo "  • Common limits: 60% (conservative), 80% (balanced), 90% (extended)"
    echo "  • Changes take effect immediately and persist across reboots"
    echo ""
    if [ "$BATTERY_FOUND" = false ]; then
        print_warning "Note: Battery charge limiting may not be supported on your system"
        print_warning "If the application doesn't work, your hardware may not support this feature"
    fi
}

# Main installation process
main() {
    print_status "Starting installation process..."
    
    install_system_deps
    check_battery_support
    install_python_package
    create_desktop_entry
    setup_systemd_service
    show_completion
}

# Run main installation
main