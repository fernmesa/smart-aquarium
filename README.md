# 🐠 Smart Aquarium with Raspberry Pi

A complete open-source aquarium controller system based on **reef-pi** with temperature monitoring, pH measurement, live camera streaming, and remote web dashboard.

**English** | [Español](./docs/README_ES.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.9+](https://img.shields.io/badge/Python-3.9+-blue)](https://www.python.org/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-red)](https://www.raspberrypi.com/)
[![reef-pi](https://img.shields.io/badge/reef--pi-latest-green)](https://reef-pi.github.io/)

---

## 📸 Features

- **🌡️ Temperature Monitoring** - DS18B20 sensors with real-time graphs
- **⚗️ pH Measurement** - Analog pH sensors via ADS1115 ADC
- **📷 Live Camera** - Raspberry Pi CSI camera with streaming
- **📊 Web Dashboard** - Responsive interface (local + remote)
- **🔔 Alerts** - Email notifications for parameter changes
- **⏰ Automation** - Scheduled equipment control (lights, pumps, heaters)
- **🌐 Remote Access** - Secure HTTPS + VPN options
- **📱 Mobile Friendly** - Works on phones and tablets

---

## 🚀 Quick Start

### Hardware Requirements (EUR €193-373)

| Component | Model | Quantity | Price | Notes |
|-----------|-------|----------|-------|-------|
| **CPU** | Raspberry Pi 4 4GB | 1 | €70 | Or Pi 5 8GB (€130) |
| **Storage** | MicroSD 64GB | 1 | €15 | SanDisk/Kingston |
| **Display** | 3.5" TFT SPI | 1 | €20 | Or 7" official (€80) |
| **Camera** | Pi Camera V2 | 1 | €30 | CSI connector |
| **Temp Sensor** | DS18B20 waterproof | 2-3 | €5 | Submersible |
| **ADC Converter** | ADS1115 16-bit | 1 | €8 | For analog sensors |
| **pH Sensor** | Analog 0-5V | 1 | €20 | Optional |
| **Relay Module** | 8-channel 5V | 1 | €12 | Optional automation |
| **Casing** | Acrylic Pi case | 1 | €20 | |
| **Power Supply** | USB-C 5V 3A | 1 | €15 | |
| **Cables/Connectors** | Various | - | €10 | |
| **TOTAL** | | | **€225** | |

**[📋 Complete Bill of Materials](./docs/BOM.md)**

---

### Installation (5 steps, 30 minutes)

#### 1. Flash Raspberry Pi OS

```bash
# Download Raspberry Pi Imager
# https://www.raspberrypi.com/software/

# Or manually:
wget https://downloads.raspberrypi.com/raspios_arm64_lite_latest.img.xz
xzcat raspios_arm64_lite_latest.img.xz | sudo dd of=/dev/sdX bs=4M

# Boot and SSH in
ssh pi@raspberry.local  # or find IP with nmap
# Default password: raspberry
```

#### 2. Clone & Install

```bash
# SSH into Pi
ssh pi@[YOUR_PI_IP]

# Download this repo
git clone https://github.com/yourusername/smart-aquarium.git
cd smart-aquarium

# Run installer
chmod +x install.sh
./install.sh

# Answer prompts:
# - Aquarium name? My Aquarium
# - Admin password? [strong password]
# - WiFi SSID? [your network]
# - WiFi password? [your password]
```

#### 3. Configure Sensors

```bash
# SSH into Pi
ssh pi@[YOUR_PI_IP]

# Test I2C devices (ADS1115 should appear as 0x48)
i2cdetect -y 1

# Test temperature sensor
cd ~/smart-aquarium
python3 scripts/test_sensors.py

# Web dashboard: http://[YOUR_PI_IP]:8080
# Default: admin / [your password]
```

#### 4. Add Sensors via Web Dashboard

- Login to `http://[YOUR_PI_IP]:8080`
- **Settings** → **Equipment** → **Add Sensor**
  - Type: `1-Wire` (for DS18B20)
  - GPIO: `4`
  - Name: `Main Tank`

- **Add Analog Sensor**
  - Type: `ADS1115 (I2C)`
  - Address: `0x48`
  - Channel: `0`
  - Type: `pH`
  - Range: `0-14`

#### 5. Setup Camera

```bash
# Enable camera in raspi-config
ssh pi@[YOUR_PI_IP]
sudo raspi-config
# Interface Options → Camera → Enable → Reboot

# Start camera stream
systemctl restart motion

# Access stream: http://[YOUR_PI_IP]:8081
```

**Done!** Your dashboard is live at `http://[YOUR_PI_IP]:8080`

---

## 🔌 Wiring Diagrams

### Temperature Sensor (DS18B20)

```
┌──────────────┐
│ DS18B20      │
├──────────────┤
│ VCC (red)  ──→ 3.3V (pin 1)
│ DATA (yellow)→ GPIO 4 (pin 7)  + 4.7kΩ pull-up
│ GND (black) ──→ GND (pin 6)
└──────────────┘

Pull-up resistor: 4.7kΩ between DATA and 3.3V
```

### pH Sensor with ADS1115

```
┌──────────────┐        ┌─────────────┐
│ pH Sensor    │        │ ADS1115     │
│ (0-5V)       │        │ 16-bit ADC  │
├──────────────┤        ├─────────────┤
│ Output       │──┬──┤  │ A0 (input)  │
│              │  │  │  │             │
│              │ 10kΩ  10kΩ (voltage divider)
│              │  │  │  │             │
│              │  └──┼──→ GND         │
└──────────────┘     │  │             │
                    ~2.5V safe for Pi │
                     │  │             │
                     │  │ SDA ←──→ GPIO 2 (pin 3)
                     │  │ SCL ←──→ GPIO 3 (pin 5)
                     │  │ GND ←──→ GND (pin 9)
                     │  │ VDD ←──→ 3.3V (pin 1)
                     └──┴─────────────┘
```

### Camera (CSI Connector)

```
Raspberry Pi          Camera Module V2
┌──────────────┐      ┌──────────────┐
│              │      │              │
│   CSI Port   │◄─────│ FPC Ribbon   │
│ (near USB)   │      │ Cable        │
│              │      │              │
└──────────────┘      └──────────────┘

⚠️ Silver contacts face HDMI side on Pi
⚠️ Silver contacts face lens on camera
```

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Raspberry Pi 4/5                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │         reef-pi (Web Dashboard)                  │   │
│  │  ├─ Settings                                     │   │
│  │  ├─ Equipment Control                            │   │
│  │  ├─ Sensor Monitoring                            │   │
│  │  ├─ Alerts & Automation                          │   │
│  │  └─ Live Charts                                  │   │
│  └──────────────────────────────────────────────────┘   │
│             ↓         ↓         ↓         ↓              │
│  ┌─────────┴─────────┴─────────┴─────────┐             │
│  │    GPIO / I2C / 1-Wire Interfaces     │             │
│  └──┬──────────────┬─────────────┬──────┬┘             │
│     │              │             │      │               │
│  DS18B20×2      ADS1115        Motion  Relay           │
│  (1-Wire)       (I2C)         (USB)   (GPIO)           │
│     │              │             │      │               │
│  Tank ──→      pH Sensor     Camera   Lights           │
│  Air            (analog)     (CSI)    Heater           │
│                                       Pump             │
│                                                           │
└─────────────────────────────────────────────────────────┘
        ↓
   [ Internet ]
        ↓
┌─────────────────────────────────────────────────────────┐
│              Remote Access (HTTPS/VPN)                   │
│      https://youraquarium.duckdns.org:8080             │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
smart-aquarium/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── install.sh                         # Automated installation
├── uninstall.sh                       # Cleanup script
│
├── docs/
│   ├── README_ES.md                   # Spanish documentation
│   ├── BOM.md                         # Bill of Materials
│   ├── WIRING.md                      # Detailed wiring guide
│   ├── SENSORS.md                     # Sensor calibration & testing
│   ├── REMOTE_ACCESS.md               # HTTPS + VPN setup
│   ├── TROUBLESHOOTING.md             # Common issues & fixes
│   ├── ARCHITECTURE.md                # System design deep-dive
│   └── CONTRIBUTE.md                  # How to contribute
│
├── scripts/
│   ├── test_sensors.py                # Sensor functionality test
│   ├── calibrate_ph.py                # pH sensor calibration
│   ├── install_reef-pi.sh             # reef-pi setup
│   ├── setup_camera.sh                # Camera + motion config
│   ├── setup_remote.sh                # HTTPS + DuckDNS setup
│   ├── health_check.sh                # System status monitor
│   └── backup.sh                      # Data backup utility
│
├── config/
│   ├── reef-pi.conf.example           # reef-pi config template
│   ├── motion.conf.example            # Motion camera config
│   ├── nginx.conf.example             # Reverse proxy example
│   └── ads1115-config.json            # ADS1115 settings
│
├── systemd/
│   ├── reef-pi.service                # reef-pi systemd unit
│   ├── motion.service                 # Camera stream unit
│   └── health-check.timer             # Periodic health check
│
├── docker/                            # (Optional containerization)
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── hardware/
    ├── fritzing/                      # Electrical schematics
    │   ├── temperature_sensor.fzz
    │   ├── ph_sensor_ads1115.fzz
    │   ├── complete_system.fzz
    │   └── camera_csi.fzz
    └── 3d-models/                     # Case designs
        ├── case_3.5inch_screen.stl
        ├── sensor_mount.stl
        └── camera_holder.stl
```

---

## 🔧 Configuration

### Basic Settings (Web UI)

1. **Login**: `http://[YOUR_PI_IP]:8080`
2. **Settings** → Configure:
   - Aquarium name
   - Temperature thresholds
   - Alert recipients
   - Automation schedules

### Advanced Settings (SSH)

```bash
# Edit reef-pi config
nano ~/.reef-pi/reef-pi.conf

# Key parameters:
# - admin_password: Change admin password
# - port: 8080 (web server port)
# - db_path: /tmp/reef-pi.db (data storage)
# - notifications: Email settings
# - webhooks: GoHighLevel / external integration
```

---

## 📈 Monitoring & Alerts

### Email Alerts Setup

```bash
# Via Web Dashboard:
# Settings → Notifications → Email
# - SMTP: smtp.gmail.com:587
# - User: your@gmail.com
# - Password: [app-specific password]
# - Alerts:
#   ✓ Temperature > 28°C
#   ✓ Temperature < 23°C
#   ✓ pH < 6.8 or > 7.5
#   ✓ Sensor offline
```

### Webhook Integration (GoHighLevel Example)

```bash
# Via SSH:
nano ~/.reef-pi/reef-pi.conf

# Add:
webhook_enabled=true
webhook_url="https://api.gohighlevel.com/v1/webhooks/custom"
webhook_auth="Bearer YOUR_TOKEN"

# Every sensor reading → webhook to GoHighLevel
```

### Health Check

```bash
# Automated system check every 5 minutes
systemctl status health-check.timer

# Manual check:
./scripts/health_check.sh

# Output:
# ✅ reef-pi running
# ✅ Sensors reporting (Tank: 25.3°C, pH: 7.1)
# ✅ Camera streaming at 30fps
# ✅ Disk usage: 28%
# ✅ CPU temp: 52°C
# ✅ Internet: OK
```

---

## 🌐 Remote Access

### Option A: HTTPS via DuckDNS (Recommended)

```bash
# 1. Register free domain at https://www.duckdns.org
# 2. Run setup:
./scripts/setup_remote.sh

# 3. Follow prompts:
# - DuckDNS token: [your_token]
# - Domain: myaquarium.duckdns.org

# 4. Access remotely:
# https://myaquarium.duckdns.org:8080
# (auto-redirects to HTTPS, auto-renews SSL)
```

### Option B: VPN via WireGuard (More Secure)

```bash
# Setup instructions in: docs/REMOTE_ACCESS.md

# Quick start:
./scripts/setup_vpn.sh

# Connect from anywhere:
# - Download WireGuard app on phone/laptop
# - Import config file
# - Access via: http://192.168.1.50:8080 (over VPN)
```

---

## 🧪 Testing & Calibration

### Test All Sensors

```bash
./scripts/test_sensors.py

# Output:
# Testing DS18B20 sensors...
# ✅ Sensor 1 (Tank): 25.3°C
# ✅ Sensor 2 (Air): 22.1°C
# 
# Testing ADS1115...
# ✅ ADC responding at 0x48
# 
# Testing pH sensor...
# ✅ Raw value: 2048 (calibrated: 7.0 pH)
# 
# Testing camera...
# ✅ Camera detected, resolution 3280x2464
# ✅ Stream accessible at http://localhost:8081
```

### Calibrate pH Sensor

```bash
# Standard buffer solutions (pH 4.0, 7.0, 10.0)
./scripts/calibrate_ph.py

# Interactive prompts:
# 1. Immerse probe in pH 7.0 solution
# 2. Enter displayed voltage: 2.048V
# 3. Immerse probe in pH 4.0 solution
# 4. Enter displayed voltage: 2.724V
# 5. [Calibration saved to config]
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Camera not detected** | Enable CSI in `raspi-config` → Reboot |
| **ADS1115 not found** | Check I2C: `i2cdetect -y 1` (should show 0x48) |
| **pH readings stuck at 0** | Check voltage divider (10kΩ + 10kΩ) |
| **Web dashboard won't load** | `sudo systemctl status reef-pi` |
| **Camera stream lagging** | Reduce `stream_quality` in motion.conf |
| **Disk fills up quickly** | Delete old logs: `journalctl --vacuum=10G` |
| **Temperature sensor offline** | Test with `./scripts/test_sensors.py` |
| **Remote access not working** | Check port forwarding, firewall rules |

**[Full Troubleshooting Guide](./docs/TROUBLESHOOTING.md)**

---

## 📚 Documentation

- **[Installation Guide](./docs/INSTALLATION.md)** - Step-by-step setup
- **[Sensor Guide](./docs/SENSORS.md)** - Calibration & troubleshooting
- **[Wiring Diagrams](./docs/WIRING.md)** - Hardware connections
- **[Remote Access](./docs/REMOTE_ACCESS.md)** - HTTPS & VPN setup
- **[Architecture](./docs/ARCHITECTURE.md)** - System design
- **[Contribution Guide](./docs/CONTRIBUTE.md)** - How to contribute

---

## 🤝 Contributing

We welcome contributions! Please:

1. **Fork** this repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

See [CONTRIBUTE.md](./docs/CONTRIBUTE.md) for detailed guidelines.

### Ideas for Contributions

- 🌍 Additional language translations
- 📱 Mobile app (React Native / Flutter)
- 🧊 Support for water level sensors
- 💧 Support for conductivity/salinity sensors
- 🤖 AI-powered anomaly detection
- 📊 Prometheus metrics export
- 🐳 Docker containerization
- 📲 Telegram bot notifications
- 🔄 Data export to InfluxDB

---

## 📜 License

This project is licensed under the **MIT License** - see [LICENSE](./LICENSE) file for details.

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software... (standard MIT terms)
```

---

## 🙏 Acknowledgments

- **[reef-pi](https://github.com/reef-pi/reef-pi)** - Aquarium controller foundation
- **[Raspberry Pi Foundation](https://www.raspberrypi.org/)** - Hardware & support
- **Community contributors** - Bug reports, ideas, translations

---

## 📞 Support

### Getting Help

- **💬 GitHub Issues** - Report bugs or request features
- **📖 Documentation** - Check [docs/](./docs/) for answers
- **🔗 Links**
  - [reef-pi docs](https://reef-pi.github.io/)
  - [Raspberry Pi docs](https://www.raspberrypi.com/documentation/)
  - [Adafruit ADS1115](https://learn.adafruit.com/adafruit-4-channel-adc-breakouts)

### Community

- Join our [GitHub Discussions](https://github.com/yourusername/smart-aquarium/discussions)
- Follow [@SmartAquariumPI](https://twitter.com/smartaquariumpi) (if applicable)

---

## ⭐ Show Your Support

If this project helped you, please **star** ⭐ it on GitHub!

```bash
# Your aquarium is now smart! 🐠🤖
# Happy aquascaping!
```

---

**Last Updated**: June 2026  
**Maintainer**: [Your Name / GitHub Handle]  
**Status**: ✅ Active Development
