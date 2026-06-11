# Contributing to Smart Aquarium

Thank you for your interest in contributing! We welcome contributions from the community. This document provides guidelines and instructions for contributing to the Smart Aquarium project.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful, constructive, and professional in all interactions.

- **Be respectful** of differing opinions and experiences
- **Be inclusive** and welcome all skill levels
- **Be constructive** in feedback and discussions
- **Report issues** privately if they involve safety concerns

## Getting Started

### Prerequisites

- Raspberry Pi 4 or 5 with Raspberry Pi OS
- Basic knowledge of Linux/Bash
- Git installed locally
- GitHub account

### Setup Development Environment

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/smart-aquarium.git
cd smart-aquarium

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/smart-aquarium.git

# Create a feature branch
git checkout -b feature/your-feature-name

# Install development dependencies
sudo ./install.sh --dev  # (if available)
```

## How to Contribute

### 1. Report Bugs

If you find a bug, please open a GitHub Issue with:

**Title**: Clear, descriptive title
```
Bug: Temperature sensor not updating
```

**Description**: Include:
- Hardware setup (Pi model, sensors, etc)
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs or error messages

**Example**:
```markdown
## Bug Report: DS18B20 Not Reading

### Hardware
- Raspberry Pi 4 4GB
- DS18B20 waterproof sensor
- 4.7kΩ pull-up resistor

### Steps to Reproduce
1. Connect DS18B20 to GPIO 4
2. Run `python3 scripts/test_sensors.py`
3. Observe output

### Expected
```
✓ Sensor 1 (Tank): 25.3°C
```

### Actual
```
✗ No 1-Wire sensors found
```

### Environment
- Raspberry Pi OS version: Bookworm
- reef-pi version: latest
```

### 2. Request Features

Open a GitHub Issue with:

**Title**: Clear feature description
```
Feature: Support for water level sensor
```

**Description**: Include:
- Use case / motivation
- Proposed solution
- Alternatives considered
- Hardware involved (if applicable)

**Example**:
```markdown
## Feature Request: Water Level Monitoring

### Motivation
Prevent tank overflows and enable auto water change detection

### Proposed Solution
Add support for:
- Capacitive water level sensors
- Float switches
- Alerts when level too low/high

### Hardware
- Sensor model: [example]
- Cost: €15-25

### Priority
Medium - would improve safety
```

### 3. Submit Code Changes

#### Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/add-water-level-sensor
   ```

2. **Make your changes**
   - Follow code style guidelines (see below)
   - Test thoroughly on actual hardware
   - Add comments for complex logic
   - Update documentation if needed

3. **Commit with clear messages**
   ```bash
   git commit -m "Add water level sensor support
   
   - Add ADS1115 water level sensor class
   - Integrate with reef-pi dashboard
   - Include calibration script
   - Closes #42"
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/add-water-level-sensor
   ```

5. **Open a Pull Request**
   - Title: Concise description
   - Description: Explain changes, reference issues
   - Screenshots (if UI changes)
   - Test results on hardware

#### Code Style Guidelines

**Python**
```python
# Use PEP 8 style
# - 4-space indentation
# - snake_case for functions/variables
# - UPPERCASE for constants
# - Type hints where helpful

def read_temperature(sensor_id: int) -> float:
    """
    Read temperature from DS18B20 sensor.
    
    Args:
        sensor_id: Index of temperature sensor (0, 1, 2, ...)
        
    Returns:
        Temperature in Celsius
        
    Raises:
        SensorError: If sensor not responding
    """
    try:
        sensor = W1ThermSensor.get_available_sensors()[sensor_id]
        return sensor.get_temperature()
    except IndexError:
        raise SensorError(f"Sensor {sensor_id} not found")
```

**Bash**
```bash
#!/bin/bash
# Use strict mode
set -euo pipefail

# Use meaningful variable names
SENSOR_GPIO_PIN=4
SAMPLING_INTERVAL=60

# Add error handling
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo "Error: python3 not installed"
        exit 1
    fi
}
```

**Configuration Files**
```json
{
  "sensor_name": "Main Tank",
  "sensor_type": "ds18b20",
  "gpio_pin": 4,
  "update_interval_seconds": 60,
  "thresholds": {
    "min_celsius": 23,
    "max_celsius": 28
  }
}
```

### 4. Documentation Updates

To improve documentation:

1. Clone and edit the relevant file in `docs/`
2. Follow Markdown style:
   ```markdown
   # Heading 1
   ## Heading 2
   ### Heading 3
   
   Paragraph text with **bold** and *italic*.
   
   - Bullet list
   - With items
   
   1. Numbered list
   2. With items
   
   ```code block```
   ```

3. Include examples and diagrams (ASCII art okay)
4. Update table of contents if adding new sections

### 5. Translation Contributions

Help translate documentation to other languages:

1. Create `docs/README_XX.md` (where XX = language code)
2. Translate content carefully, maintaining formatting
3. Include disclaimer: "Translation contributed by [Your Name]"
4. Open Pull Request

**Supported Languages:**
- 🇬🇧 English (original)
- 🇪🇸 Spanish (es)
- 🇩🇪 German (de)
- 🇫🇷 French (fr)
- 🇮🇹 Italian (it)
- 🇵🇹 Portuguese (pt)

## Pull Request Process

### Before Submitting

- [ ] Code follows project style guidelines
- [ ] All new features include documentation
- [ ] Commits have clear, descriptive messages
- [ ] Tested on actual Raspberry Pi hardware
- [ ] No unrelated changes mixed in
- [ ] Updated CHANGELOG.md (if applicable)

### PR Description Template

```markdown
## Description
Brief explanation of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Hardware Tested
- [ ] Raspberry Pi 4 4GB
- [ ] Raspberry Pi 5 8GB
- Sensors: [list of sensors tested]

## Testing
Describe how you tested the changes:
- [ ] Unit tests passed
- [ ] Tested on actual hardware
- [ ] Tested with multiple sensor values
- [ ] Temperature reading: 25.3°C
- [ ] pH reading: 7.1

## Screenshots (if applicable)
[Paste images of UI changes]

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have updated relevant documentation
- [ ] I have tested on Raspberry Pi hardware
- [ ] I have not introduced breaking changes
- [ ] All commit messages are clear and descriptive

## References
Closes #[issue number]
```

### Review Process

1. **Automated Checks**
   - Linting (if configured)
   - Basic syntax checks
   
2. **Maintainer Review**
   - Code quality assessment
   - Hardware compatibility check
   - Documentation review
   
3. **Feedback & Iteration**
   - Address requested changes
   - Push updates to same branch
   - Discuss any disagreements constructively

4. **Merge**
   - Squash commits if requested
   - Merge to main branch
   - Close associated issues

## Development Tips

### Testing Locally

```bash
# Run sensor tests
python3 scripts/test_sensors.py

# Check reef-pi status
systemctl status reef-pi

# View logs
journalctl -u reef-pi -n 50 -f

# Test camera stream
curl http://localhost:8081

# Test web interface
curl http://localhost:8080/api/health
```

### Git Workflow

```bash
# Keep fork in sync
git fetch upstream
git rebase upstream/main

# Before pushing, check for conflicts
git merge-base --is-ancestor upstream/main HEAD || git rebase upstream/main

# Clean up commits
git rebase -i HEAD~3  # Interactive rebase last 3 commits
```

### Debugging

```bash
# Enable verbose logging
DEBUG=1 ./scripts/health_check.sh

# Check I2C devices
i2cdetect -y 1

# Test 1-Wire
cat /sys/bus/w1/devices/*/w1_slave

# Monitor system resources
top -o %MEM -b -n 1
```

## Special Interest Areas

We're especially interested in contributions for:

### High Priority
- 🐚 Water level sensor support
- 💧 Conductivity/salinity sensors
- 📱 Mobile app (React Native / Flutter)
- 🤖 AI anomaly detection
- 🧊 Reef-specific features

### Medium Priority
- 🌍 Language translations
- 📊 Data export (InfluxDB, Prometheus)
- 📲 Additional notification channels (Telegram, Discord)
- 🔄 Docker containerization
- 📈 Performance optimizations

### Community Features
- Sample configurations
- User success stories
- Video tutorials
- Integration guides

## Licenses

By contributing to Smart Aquarium, you agree that your contributions will be licensed under the MIT License.

## Questions?

- Open a GitHub Discussion
- Check existing issues/PRs first
- Ask on GitHub Issues (label as `question`)

## Attribution

Contributors will be recognized in:
- README.md contributors section
- GitHub contributors page
- CHANGELOG.md (for major contributions)

---

**Thank you for contributing to Smart Aquarium!** 🐠🤖

We appreciate your effort to make this project better for the community.
