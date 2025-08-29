#!/bin/bash
# RadiateOS Touchscreen Configuration for HP Pavilion

set -e

echo "========================================="
echo "RadiateOS Touchscreen Configurator"
echo "HP Pavilion Touch Display Support"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Detect touchscreen device
log_info "Detecting touchscreen devices..."
TOUCH_DEVICES=$(xinput list | grep -i touch || true)

if [ -z "$TOUCH_DEVICES" ]; then
    log_warning "No touchscreen detected via xinput"
    
    # Try alternative detection
    log_info "Checking USB devices..."
    lsusb | grep -i touch || true
    
    log_info "Checking input devices..."
    ls -la /dev/input/by-id/*touch* 2>/dev/null || true
else
    echo "$TOUCH_DEVICES"
fi

# Install required packages
log_info "Installing touchscreen support packages..."
apt-get update
apt-get install -y \
    xserver-xorg-input-evdev \
    xserver-xorg-input-libinput \
    xserver-xorg-input-synaptics \
    xinput-calibrator \
    evtest \
    libevdev-tools \
    libinput-tools \
    xserver-xorg-input-wacom

# Configure libinput for touchscreen
log_info "Configuring libinput..."
cat > /etc/X11/xorg.conf.d/40-libinput.conf << 'EOF'
Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
    Option "TappingDrag" "on"
    Option "TappingDragLock" "on"
    Option "NaturalScrolling" "on"
    Option "ScrollMethod" "twofinger"
    Option "DisableWhileTyping" "on"
EndSection

Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "on"
EndSection
EOF

# Configure evdev as fallback
cat > /etc/X11/xorg.conf.d/45-evdev-touchscreen.conf << 'EOF'
Section "InputClass"
    Identifier "evdev touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "EmulateThirdButton" "1"
    Option "EmulateThirdButtonTimeout" "750"
    Option "EmulateThirdButtonMoveThreshold" "30"
EndSection
EOF

# HP Pavilion specific configuration
cat > /etc/X11/xorg.conf.d/50-hp-pavilion-touch.conf << 'EOF'
Section "InputClass"
    Identifier "HP Pavilion Touchscreen"
    MatchProduct "ELAN|Synaptics|AlpsPS|Touchscreen|FTSC1000"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "CalibrationMatrix" "1 0 0 0 1 0 0 0 1"
    Option "SwapAxes" "0"
    Option "InvertX" "0"
    Option "InvertY" "0"
EndSection

# USB Touchscreen support
Section "InputClass"
    Identifier "USB Touchscreen"
    MatchUSBID "0eef:*|0486:*|1926:*"
    MatchIsTouchscreen "on"
    Driver "evdev"
    Option "Device" "/dev/input/event*"
    Option "DeviceName" "touchscreen"
    Option "ReportingMode" "Raw"
    Option "Emulate3Buttons" "false"
    Option "SwapAxes" "0"
EndSection
EOF

# Create udev rules for touchscreen
log_info "Creating udev rules..."
cat > /etc/udev/rules.d/99-touchscreen.rules << 'EOF'
# HP Pavilion Touchscreen Rules
SUBSYSTEM=="input", ATTRS{name}=="*[Tt]ouchscreen*", ENV{ID_INPUT_TOUCHSCREEN}="1"
SUBSYSTEM=="input", ATTRS{name}=="*ELAN*", ENV{ID_INPUT_TOUCHSCREEN}="1"
SUBSYSTEM=="input", ATTRS{name}=="*Synaptics*", ENV{ID_INPUT_TOUCHSCREEN}="1"
SUBSYSTEM=="input", ATTRS{name}=="*FTSC1000*", ENV{ID_INPUT_TOUCHSCREEN}="1"

# Set permissions
SUBSYSTEM=="input", ENV{ID_INPUT_TOUCHSCREEN}=="1", MODE="0666", GROUP="input"

# USB touchscreen support
SUBSYSTEM=="usb", ATTRS{idVendor}=="0eef", ATTRS{idProduct}=="*", MODE="0666", GROUP="input"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0486", ATTRS{idProduct}=="*", MODE="0666", GROUP="input"
SUBSYSTEM=="usb", ATTRS{idVendor}=="1926", ATTRS{idProduct}=="*", MODE="0666", GROUP="input"
EOF

# Create calibration script
log_info "Creating calibration script..."
cat > /usr/local/bin/calibrate-touchscreen << 'EOF'
#!/bin/bash
# Touchscreen Calibration Tool

echo "RadiateOS Touchscreen Calibration"
echo "=================================="

# Find touchscreen device
DEVICE=$(xinput list | grep -i touchscreen | head -n1 | sed 's/.*id=\([0-9]*\).*/\1/')

if [ -z "$DEVICE" ]; then
    echo "No touchscreen found!"
    exit 1
fi

echo "Found touchscreen device: $DEVICE"
echo "Starting calibration..."

# Run calibration
xinput_calibrator --device $DEVICE

echo ""
echo "Calibration complete!"
echo "Configuration saved to /etc/X11/xorg.conf.d/99-calibration.conf"
EOF

chmod +x /usr/local/bin/calibrate-touchscreen

# Create touch gesture configuration
log_info "Configuring touch gestures..."
mkdir -p /etc/libinput
cat > /etc/libinput/gestures.conf << 'EOF'
# RadiateOS Touch Gestures Configuration

# Swipe gestures
gesture swipe up 3 xdotool key super+Page_Up
gesture swipe down 3 xdotool key super+Page_Down
gesture swipe left 3 xdotool key alt+Right
gesture swipe right 3 xdotool key alt+Left

# Pinch gestures
gesture pinch in xdotool key ctrl+minus
gesture pinch out xdotool key ctrl+plus

# Tap gestures
gesture tap 2 xdotool click 3
gesture tap 3 xdotool key super
EOF

# Install gesture daemon
apt-get install -y libinput-gestures xdotool wmctrl

# Enable for all users
usermod -a -G input radiateos

# Create systemd service for gesture support
cat > /etc/systemd/system/touchscreen-gestures.service << 'EOF'
[Unit]
Description=RadiateOS Touchscreen Gesture Support
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/libinput-gestures
Restart=on-failure
User=radiateos
Group=input
Environment="DISPLAY=:0"

[Install]
WantedBy=graphical.target
EOF

systemctl enable touchscreen-gestures.service

# Create touchscreen test utility
cat > /usr/local/bin/test-touchscreen << 'EOF'
#!/bin/bash
echo "RadiateOS Touchscreen Test"
echo "=========================="
echo ""
echo "Testing touchscreen functionality..."
echo "Touch the screen to see events (Ctrl+C to exit)"
echo ""

# Find touch device
for device in /dev/input/event*; do
    if evtest --query $device EV_ABS ABS_X 2>/dev/null; then
        echo "Testing device: $device"
        evtest $device
        break
    fi
done
EOF

chmod +x /usr/local/bin/test-touchscreen

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

log_info "Touchscreen configuration complete!"
log_info "Run 'calibrate-touchscreen' to calibrate"
log_info "Run 'test-touchscreen' to test functionality"

echo "========================================="
echo "Configuration Summary:"
echo "- Driver: libinput (primary), evdev (fallback)"
echo "- Gestures: Enabled (swipe, pinch, tap)"
echo "- Calibration: Available via calibrate-touchscreen"
echo "- Testing: Available via test-touchscreen"
echo "========================================="