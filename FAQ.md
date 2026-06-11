# Frequently Asked Questions (FAQ)

## General Questions

### What is Smart Aquarium?
Smart Aquarium is an open-source aquarium controller system for Raspberry Pi. It provides automated monitoring, control, and remote access to your aquarium through a web dashboard.

### Is it only for saltwater (marine) aquariums?
No! While built on reef-pi (which focuses on marine aquariums), Smart Aquarium works perfectly for freshwater aquariums too. You can:
- Monitor temperature
- Measure pH
- Control lights and filters
- Automate water changes
- Set up alerts

### Do I need programming experience?
No! The web dashboard is completely graphical. You just:
1. Run the installer
2. Connect sensors
3. Configure via web UI

Advanced users can script automations, but it's optional.

---

## Hardware Questions

### Which Raspberry Pi model do I need?
**Minimum**: Raspberry Pi 4 with 4GB RAM (€70)
**Recommended**: Raspberry Pi 5 with 8GB RAM (€130)

Why not Pi 3 or earlier?
- Slower performance with multiple sensors
- Older models have less RAM
- Pi 4+ is well-supported for years to come

### Can I use a Raspberry Pi Zero?
Technically yes for very simple setups (1-2 sensors), but:
- Only 512MB RAM (tight for web dashboard)
- Slower CPU (sensor reading lags)
- Limited future expandability

**Not recommended** for active aquarium monitoring.

### What sensors can I connect?
Supported:
- ✅ **Temperature** (DS18B20, DHT11, MLX90614)
- ✅ **pH** (Analog sensors + ADS1115)
- ✅ **Camera** (CSI ribbon or USB)
- ✅ **Relay switches** (GPIO control)

Possible to add:
- Conductivity/TDS sensors
- Water level sensors
- ORP (redox) sensors
- Light sensors

### Do I need to solder?
Mostly no. Most connections are:
- **Plug & play**: CSI camera, USB camera
- **Jumper wires**: Temperature sensor, ADS1115
- **Optional soldering**: If adding pull-up resistors directly to sensor

Soldering skills help but aren't required.

### How much does a complete system cost?
**Basic setup**: €193-225
- Pi 4 4GB, storage, screen, sensors

**Advanced setup**: €350-400
- Pi 5 8GB, official screen, multiple sensors, relays

**Budget setup**: €120
- Pi 4, USB camera, just temperature sensor

---

## Software Questions

### What operating system does it use?
Raspberry Pi OS (Debian-based). Installation script handles all setup.

### Do I need a monitor and keyboard?
No! You can:
- Install via SSH (headless)
- Access web dashboard from any device
- Manage completely remotely

**Optional**: Small LCD screen (€20-30) for local display.

### Can I access my aquarium remotely?
Yes! Three options:

1. **HTTPS (Easiest)**
   - Free domain: DuckDNS
   - Auto SSL certificate
   - Access: `https://myaqua.duckdns.org:8080`

2. **VPN (Most Secure)**
   - WireGuard setup included
   - Private network access
   - Mobile apps available

3. **LAN Only** (No remote access)
   - Only works on same WiFi
   - No internet access needed

### Is it secure?
Yes, if configured properly:
- ✅ HTTPS/SSL encryption
- ✅ Strong passwords
- ✅ VPN option available
- ✅ Open-source (auditable code)

**Important**: 
- Change default admin password immediately
- Use strong passwords (16+ characters)
- Enable firewall
- Keep system updated

### What if I lose internet?
No problem! System works completely offline:
- Web dashboard still accessible locally
- Sensors still monitored
- Alerts save to log files
- Internet optional (only for remote access)

---

## Sensor Questions

### How do I calibrate pH sensor?
```bash
./scripts/calibrate_ph.py
```

Standard procedure:
1. Buffer solution pH 7.0 → measure voltage
2. Buffer solution pH 4.0 → measure voltage
3. System calculates calibration formula
4. Saved for future readings

Recalibrate monthly for accuracy.

### Temperature reading is wrong
Common causes:
- **Sensor not in water** → Immerse fully
- **Pull-up resistor missing** → Add 4.7kΩ resistor
- **Wire distance too long** → Keep wires < 1 meter
- **EMI interference** → Shield cables, move away from motors

Test with: `python3 scripts/test_sensors.py`

### Sensor randomly disconnects
Usually due to:
- **Loose connection** → Reseat all wires
- **Corrosion** → Use shrink tubing on connections
- **Power supply issue** → Test voltage with multimeter
- **Long wires** → Shorten or use twisted pair

### Can I add sensors after installation?
Yes! You can:
- Add new sensors anytime
- Configure in web dashboard
- No reboot needed (mostly)
- Old data preserved

---

## Camera Questions

### Which camera is best?
| Model | Price | Quality | Pros |
|-------|-------|---------|------|
| V2 | €30 | Good | Affordable, reliable |
| Module 3 | €35 | Better | Autofocus, 12MP |
| NoIR | €30 | Good | Infrared (night vision) |
| USB | €15 | Okay | Simplest setup |

**Recommendation**: Camera Module V2 or 3 (best integration).

### Camera stream is laggy
Solutions:
1. Reduce quality: `stream_quality 60` (in motion.conf)
2. Reduce frame rate: `stream_maxrate 10`
3. Lower resolution: `stream_maxrate 640x480`
4. Reduce concurrent streams

### Can I record video?
Yes! Manual recording:
```bash
libcamera-vid -t 300000 -o myfile.h264  # 5 min video
```

Auto-recording (disk space considerations):
- Recommend: NVMe or large MicroSD
- Monthly: ~10-20GB (depending on resolution)

### Can I use an IP camera instead?
Yes! Integrate via RTSP stream:
- Configure in reef-pi settings
- Add RTSP URL
- Works with network cameras

---

## Automation & Control Questions

### Can I automate light schedules?
Yes! Web dashboard allows:
- On/off times
- Gradual fade in/out
- Weekday/weekend schedules
- Seasonal adjustments

### Can I control multiple devices?
Yes! With relay modules:
- Lights (LED or regular)
- Heater (on/off control)
- Chiller (if on/off type)
- Air pump
- Solenoid valves

Each device = separate relay.

### Can I trigger actions based on sensor values?
Yes! Example automations:
- If temp > 28°C → turn on chiller
- If temp < 23°C → turn on heater
- If pH > 7.8 → alert via email
- If sensor offline > 10 min → SMS alert

Configure via web dashboard or YAML rules.

---

## Troubleshooting

### Installation fails
Common causes:
- **Wrong permissions** → Use `sudo ./install.sh`
- **Missing dependencies** → Script installs them
- **Network issue** → Check WiFi connection
- **Disk space** → Need at least 4GB free

Debug:
```bash
sudo systemctl status reef-pi
journalctl -u reef-pi -n 100
```

### Web dashboard won't load
Check:
```bash
# Is reef-pi running?
systemctl is-active reef-pi

# Is port 8080 listening?
netstat -tulpn | grep 8080

# Try directly on Pi:
curl http://localhost:8080
```

### Camera stream not working
```bash
# Check camera enabled
raspi-config  # Interface Options → Camera → Enable

# Test camera
libcamera-hello -t 5000

# Check motion service
systemctl status motion
```

### Alerts not sending
Check:
- Email settings in dashboard
- SMTP credentials correct
- Less secure apps enabled (Gmail)
- Check logs: `journalctl -u reef-pi | grep -i email`

### Sensor keeps disconnecting
Solutions:
1. Shorten wires to < 1 meter
2. Check voltage: `i2cdetect -y 1`
3. Add capacitors (100nF) near sensor
4. Use twisted pair cable

---

## Data & Backup

### How much disk space do I need?
- **OS + Software**: ~2GB
- **Monthly data logs**: ~0.5GB (per sensor)
- **Camera recordings**: ~10GB (per month)

Recommend: **32GB MicroSD minimum**

### How do I backup my data?
```bash
# Manual backup
./scripts/backup.sh

# Auto backup (daily at 2 AM)
# Configured in crontab
```

Backups include:
- Temperature history
- Settings & configurations
- Calibration data
- Video archives (optional)

### Can I export data?
Yes! Multiple formats:
- CSV (spreadsheet compatible)
- JSON (for analysis)
- InfluxDB (time-series database)
- Prometheus (monitoring)

---

## Performance & Advanced

### Can it handle many sensors?
Yes! Tested with:
- 5+ temperature sensors
- 3+ pH sensors
- 2 cameras
- Multiple automation rules

Performance remains good on Pi 4.

### What's the power consumption?
- **Idle**: 2-3 watts
- **Active monitoring**: 3-5 watts
- **With camera stream**: 5-8 watts

Can run on small solar panel + battery!

### Can I integrate with other systems?
Yes! Supported integrations:
- **Webhooks**: Send data to GoHighLevel, Zapier, etc
- **MQTT**: Connect to Home Assistant
- **REST API**: Custom integrations
- **Telegram Bot**: Get alerts on Telegram

Examples in `docs/INTEGRATIONS.md`

### How do I contribute?
See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Bug reports
- Feature requests
- Code contributions
- Documentation improvements

---

## Legal & Licenses

### Is this free?
Yes! MIT License means:
- ✅ Free to use
- ✅ Free to modify
- ✅ Free to distribute
- ✅ For personal or commercial use

Just include license in your project.

### Can I use this commercially?
Yes! You can:
- Build and sell systems
- Offer as service
- Integrate into products

See LICENSE file for terms.

---

## Still Have Questions?

- 📖 **[Full Documentation](./docs/)**
- 💬 **GitHub Discussions** (Q&A community)
- 🐛 **GitHub Issues** (bug reports, features)
- 🔗 **Links**:
  - [reef-pi docs](https://reef-pi.github.io/)
  - [Raspberry Pi docs](https://www.raspberrypi.com/documentation/)

---

**Last Updated**: June 2026  
**Maintained By**: Smart Aquarium Community
