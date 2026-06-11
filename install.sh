#!/bin/bash
#
# Smart Aquarium - Automated Installation Script
# Usage: chmod +x install.sh && ./install.sh
#
# This script sets up a complete Raspberry Pi aquarium controller system
# with reef-pi, camera streaming, and sensor monitoring.
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Smart Aquarium - Installation Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        echo "Try: sudo ./install.sh"
        exit 1
    fi
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        print_error "Could not detect OS"
        exit 1
    fi

    . /etc/os-release
    if [[ "$ID" != "raspbian" && "$ID" != "debian" ]]; then
        print_warning "This script is designed for Raspberry Pi OS (Debian-based)"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

ask_user_info() {
    echo ""
    echo -e "${BLUE}=== System Configuration ===${NC}"
    echo ""
    
    # Aquarium name
    read -p "Aquarium name (default: 'My Aquarium'): " AQUARIUM_NAME
    AQUARIUM_NAME=${AQUARIUM_NAME:-"My Aquarium"}
    
    # Admin password
    while true; do
        read -s -p "Admin password (min 8 chars): " ADMIN_PASS
        echo
        if [ ${#ADMIN_PASS} -lt 8 ]; then
            print_warning "Password too short. Minimum 8 characters."
            continue
        fi
        read -s -p "Confirm password: " ADMIN_PASS_CONFIRM
        echo
        if [ "$ADMIN_PASS" = "$ADMIN_PASS_CONFIRM" ]; then
            break
        else
            print_error "Passwords don't match. Try again."
        fi
    done
    
    # WiFi (optional)
    echo ""
    read -p "WiFi SSID (optional, press enter to skip): " WIFI_SSID
    if [ ! -z "$WIFI_SSID" ]; then
        read -s -p "WiFi password: " WIFI_PASS
        echo
    fi
    
    echo ""
    echo -e "${BLUE}=== Sensor Configuration ===${NC}"
    echo ""
    
    # Temperature sensors
    read -p "Number of temperature sensors (default: 2): " TEMP_SENSORS
    TEMP_SENSORS=${TEMP_SENSORS:-2}
    
    # pH sensor
    read -p "Do you have a pH sensor? (y/N): " HAS_PH_SENSOR
    HAS_PH_SENSOR=${HAS_PH_SENSOR:-n}
    
    # Relays
    read -p "Do you have relay modules? (y/N): " HAS_RELAYS
    HAS_RELAYS=${HAS_RELAYS:-n}
    
    echo ""
}

update_system() {
    print_step "Updating system packages..."
    apt-get update
    apt-get upgrade -y
}

install_dependencies() {
    print_step "Installing required dependencies..."
    
    apt-get install -y \
        git \
        curl \
        wget \
        build-essential \
        python3 \
        python3-pip \
        python3-dev \
        i2c-tools \
        libssl-dev \
        libffi-dev \
        npm \
        docker.io \
        mosquitto \
        mosquitto-clients
    
    print_step "Dependencies installed"
}

enable_interfaces() {
    print_step "Enabling required interfaces..."
    
    # Check if raspi-config is available
    if command -v raspi-config &> /dev/null; then
        # Enable I2C
        sudo raspi-config nonint do_i2c 0
        print_step "I2C interface enabled"
        
        # Enable 1-Wire (GPIO 4)
        if ! grep -q "dtoverlay=w1-gpio" /boot/firmware/config.txt; then
            echo "dtoverlay=w1-gpio,gpiopin=4" | sudo tee -a /boot/firmware/config.txt > /dev/null
            print_step "1-Wire interface enabled on GPIO 4"
        fi
        
        # Enable Camera if available
        sudo raspi-config nonint do_camera 0
        print_step "Camera interface enabled"
    else
        print_warning "raspi-config not found. Please manually enable I2C, 1-Wire, and Camera in raspi-config"
    fi
}

install_reef_pi() {
    print_step "Installing reef-pi aquarium controller..."
    
    if [ ! -d ~/.reef-pi ]; then
        mkdir -p ~/.reef-pi
    fi
    
    # Download reef-pi (latest from GitHub)
    cd /opt
    git clone https://github.com/reef-pi/reef-pi.git || {
        print_warning "reef-pi already exists, pulling latest..."
        cd reef-pi && git pull
        cd ..
    }
    
    cd reef-pi
    print_step "Building reef-pi (this may take a few minutes)..."
    make build 2>&1 | tail -20
    
    # Create config file
    cat > ~/.reef-pi/reef-pi.conf << EOF
{
  "port": 8080,
  "read_only": false,
  "admin_password": "$ADMIN_PASS",
  "db_path": "/home/pi/.reef-pi/data.db",
  "connectors": {
    "connector_name": "connector_type"
  },
  "equipment": [],
  "sensors": [],
  "automations": [],
  "notifications": {
    "email_enabled": false,
    "webhook_enabled": false
  }
}
EOF
    
    print_step "reef-pi installed and configured"
}

setup_camera() {
    print_step "Setting up camera system..."
    
    apt-get install -y \
        libcamera-apps \
        motion
    
    # Create motion config
    cat > /etc/motion/motion.conf << 'EOF'
# Motion configuration for Raspberry Pi Camera
daemon off
stream_port 8081
stream_quality 80
stream_maxrate 15
stream_localhost off
webcontrol_port 8084
text_left AQUARIUM
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/motion.service << 'EOF'
[Unit]
Description=Motion Detection Camera Stream
After=network.target

[Service]
Type=forking
User=pi
ExecStart=/usr/bin/motion -c /etc/motion/motion.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable motion
    
    print_step "Camera streaming configured"
}

install_python_libraries() {
    print_step "Installing Python libraries for sensors..."
    
    pip3 install --upgrade pip
    pip3 install \
        RPi.GPIO \
        adafruit-circuitpython-ads1x15 \
        w1thermsensor \
        requests \
        pyyaml
    
    print_step "Python libraries installed"
}

create_systemd_services() {
    print_step "Creating systemd services..."
    
    # reef-pi service
    cat > /etc/systemd/system/reef-pi.service << 'EOF'
[Unit]
Description=reef-pi Aquarium Controller
After=network.target mosquitto.service

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/reef-pi
ExecStart=/opt/reef-pi/reef-pi
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Health check timer
    cat > /etc/systemd/system/aquarium-health-check.service << 'EOF'
[Unit]
Description=Aquarium Health Check
After=network.target

[Service]
Type=oneshot
User=pi
ExecStart=/home/pi/smart-aquarium/scripts/health_check.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/aquarium-health-check.timer << 'EOF'
[Unit]
Description=Run aquarium health check every 5 minutes
Requires=aquarium-health-check.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable reef-pi
    systemctl enable aquarium-health-check.timer
    
    print_step "Systemd services created"
}

setup_firewall() {
    print_step "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp    # SSH
        ufw allow 8080/tcp  # reef-pi
        ufw allow 8081/tcp  # Camera stream
        ufw allow 8084/tcp  # Motion control
        ufw enable
        print_step "Firewall configured"
    else
        print_warning "UFW not installed, skipping firewall setup"
    fi
}

create_test_scripts() {
    print_step "Creating test scripts..."
    
    mkdir -p /home/pi/smart-aquarium/scripts
    
    # Test sensors script
    cat > /home/pi/smart-aquarium/scripts/test_sensors.py << 'EOF'
#!/usr/bin/env python3
"""Test all connected sensors"""

import os
import sys

print("=" * 50)
print("Smart Aquarium - Sensor Test")
print("=" * 50)
print()

# Test 1-Wire sensors (DS18B20)
print("Testing 1-Wire temperature sensors...")
try:
    from w1thermsensor import W1ThermSensor
    sensors = W1ThermSensor.get_available_sensors()
    if sensors:
        for sensor in sensors:
            temp = sensor.get_temperature()
            print(f"  ✓ Sensor {sensor.id}: {temp:.1f}°C")
    else:
        print("  ✗ No 1-Wire sensors found (check wiring)")
except Exception as e:
    print(f"  ✗ Error: {e}")

print()

# Test ADS1115 (I2C ADC)
print("Testing ADS1115 ADC (I2C)...")
try:
    import board
    import busio
    from adafruit_ads1x15.analog_in import AnalogIn
    import adafruit_ads1x15.ads1115 as ADS

    i2c = busio.I2C(board.SCL, board.SDA)
    ads = ADS.ADS1115(i2c, address=0x48)
    
    channel0 = AnalogIn(ads, ADS.P0)
    value = channel0.voltage
    print(f"  ✓ ADS1115 detected at 0x48")
    print(f"  ✓ Channel 0 voltage: {value:.3f}V")
except Exception as e:
    print(f"  ✗ ADS1115 not found: {e}")

print()

# Test camera
print("Testing Camera...")
try:
    from libcamera import get_cameras
    cameras = get_cameras()
    if cameras:
        print(f"  ✓ Camera found: {cameras[0].model}")
    else:
        print("  ✗ No cameras found (enable in raspi-config)")
except Exception as e:
    print(f"  ✗ Camera error: {e}")

print()
print("=" * 50)
print("Test complete!")
EOF
    
    chmod +x /home/pi/smart-aquarium/scripts/test_sensors.py
    
    print_step "Test scripts created"
}

show_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}System Information:${NC}"
    echo "  Aquarium Name: ${AQUARIUM_NAME}"
    echo "  Temperature Sensors: ${TEMP_SENSORS}"
    echo "  pH Sensor: ${HAS_PH_SENSOR}"
    echo "  Relay Modules: ${HAS_RELAYS}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo "1. Reboot your Raspberry Pi:"
    echo "   sudo reboot"
    echo ""
    echo "2. SSH back in and check status:"
    echo "   systemctl status reef-pi"
    echo ""
    echo "3. Test your sensors:"
    echo "   python3 /home/pi/smart-aquarium/scripts/test_sensors.py"
    echo ""
    echo "4. Access the web dashboard:"
    echo "   http://$(hostname -I | awk '{print $1}'):8080"
    echo "   Username: admin"
    echo "   Password: [the password you set]"
    echo ""
    echo "5. View live camera stream:"
    echo "   http://$(hostname -I | awk '{print $1}'):8081"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "  ⚠ Change your admin password immediately in the dashboard"
    echo "  ⚠ Enable I2C, 1-Wire, and Camera in raspi-config"
    echo "  ⚠ Add your sensors in Settings → Equipment"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  📖 https://github.com/yourusername/smart-aquarium"
    echo "  📚 See docs/ folder for detailed guides"
    echo ""
}

main() {
    print_header
    check_root
    check_os
    
    echo -e "${YELLOW}This script will:${NC}"
    echo "  • Update system packages"
    echo "  • Install dependencies (Docker, Python, etc)"
    echo "  • Enable I2C, 1-Wire, Camera interfaces"
    echo "  • Install reef-pi aquarium controller"
    echo "  • Setup camera streaming"
    echo "  • Configure sensor monitoring"
    echo "  • Create systemd services"
    echo ""
    read -p "Continue with installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
    
    ask_user_info
    update_system
    install_dependencies
    enable_interfaces
    install_reef_pi
    setup_camera
    install_python_libraries
    create_systemd_services
    setup_firewall
    create_test_scripts
    show_summary
}

# Error handler
trap 'print_error "Installation failed on line $LINENO"; exit 1' ERR

# Run main
main

exit 0
