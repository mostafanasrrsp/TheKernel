#!/bin/bash
# RadiateOS Display Server Setup (X11/Wayland)

set -e

echo "============================================"
echo "RadiateOS Display Server Configuration"
echo "X11 with Wayland Support"
echo "============================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Install display servers
log_info "Installing display server components..."
apt-get update
apt-get install -y \
    xorg \
    xserver-xorg \
    xserver-xorg-core \
    xserver-xorg-input-all \
    xserver-xorg-video-all \
    xinit \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    wayland \
    wayland-protocols \
    weston \
    xwayland \
    libwayland-client0 \
    libwayland-server0 \
    libwayland-egl1 \
    gnome-session-wayland \
    mutter

# Configure X11
log_info "Configuring X11..."
cat > /etc/X11/xorg.conf << 'EOF'
Section "ServerLayout"
    Identifier     "RadiateOS Layout"
    Screen      0  "Screen0" 0 0
    InputDevice    "Keyboard0" "CoreKeyboard"
    InputDevice    "Mouse0" "CorePointer"
    Option         "AllowEmptyInput" "false"
EndSection

Section "Files"
    ModulePath   "/usr/lib/xorg/modules"
    FontPath     "/usr/share/fonts/X11/misc"
    FontPath     "/usr/share/fonts/X11/100dpi/:unscaled"
    FontPath     "/usr/share/fonts/X11/75dpi/:unscaled"
    FontPath     "/usr/share/fonts/X11/Type1"
    FontPath     "/usr/share/fonts/X11/100dpi"
    FontPath     "/usr/share/fonts/X11/75dpi"
EndSection

Section "Module"
    Load  "dbe"
    Load  "dri"
    Load  "dri2"
    Load  "extmod"
    Load  "glx"
    Load  "record"
EndSection

Section "InputDevice"
    Identifier  "Keyboard0"
    Driver      "kbd"
    Option      "XkbLayout" "us"
EndSection

Section "InputDevice"
    Identifier  "Mouse0"
    Driver      "mouse"
    Option      "Protocol" "auto"
    Option      "Device" "/dev/input/mice"
    Option      "ZAxisMapping" "4 5 6 7"
EndSection

Section "Monitor"
    Identifier   "Monitor0"
    VendorName   "HP"
    ModelName    "Pavilion Display"
    Option       "DPMS" "true"
EndSection

Section "Device"
    Identifier  "Device0"
    Driver      "nvidia"
    VendorName  "NVIDIA Corporation"
    Option      "NoLogo" "true"
    Option      "UseEDID" "true"
    Option      "RenderAccel" "true"
    Option      "AllowGLXWithComposite" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device     "Device0"
    Monitor    "Monitor0"
    DefaultDepth     24
    Option         "Stereo" "0"
    Option         "metamodes" "nvidia-auto-select +0+0"
    Option         "SLI" "Off"
    Option         "MultiGPU" "Off"
    Option         "BaseMosaic" "off"
    SubSection "Display"
        Depth     24
        Modes    "1920x1080" "1680x1050" "1600x900" "1440x900" "1366x768" "1280x1024" "1280x720" "1024x768"
    EndSubSection
EndSection

Section "Extensions"
    Option "Composite" "Enable"
EndSection
EOF

# Configure Wayland
log_info "Configuring Wayland..."
mkdir -p /etc/wayland
cat > /etc/wayland/weston.ini << 'EOF'
[core]
shell=desktop-shell.so
backend=drm-backend.so
idle-time=300
require-input=false

[keyboard]
keymap_rules=evdev
keymap_model=pc105
keymap_layout=us

[output]
name=HDMI-A-1
mode=1920x1080@60
transform=normal

[output]
name=eDP-1
mode=preferred
transform=normal

[launcher]
icon=/usr/share/icons/hicolor/24x24/apps/firefox.png
path=/usr/bin/firefox

[launcher]
icon=/usr/share/icons/hicolor/24x24/apps/utilities-terminal.png
path=/usr/bin/gnome-terminal

[input-method]
path=/usr/lib/weston/weston-keyboard

[screen-share]
command=/usr/bin/weston --backend=rdp-backend.so --shell=fullscreen-shell.so --no-clients-resize
EOF

# Create session selector
log_info "Creating session selector..."
cat > /usr/local/bin/radiateos-session << 'EOF'
#!/bin/bash
# RadiateOS Session Manager

echo "RadiateOS Display Server Selection"
echo "=================================="
echo "1) X11 Session (Stable)"
echo "2) Wayland Session (Modern)"
echo "3) Wayland with XWayland (Hybrid)"
echo ""

read -p "Select session type (1-3): " SESSION

case $SESSION in
    1)
        echo "Starting X11 session..."
        exec startx
        ;;
    2)
        echo "Starting Wayland session..."
        export XDG_SESSION_TYPE=wayland
        export GDK_BACKEND=wayland
        export QT_QPA_PLATFORM=wayland
        exec weston
        ;;
    3)
        echo "Starting Hybrid session..."
        export XDG_SESSION_TYPE=wayland
        export GDK_BACKEND=wayland,x11
        export QT_QPA_PLATFORM=wayland;xcb
        exec gnome-session --session=gnome-wayland
        ;;
    *)
        echo "Invalid selection, starting default X11..."
        exec startx
        ;;
esac
EOF

chmod +x /usr/local/bin/radiateos-session

# Configure GDM for display manager
log_info "Configuring display manager..."
cat > /etc/gdm3/custom.conf << 'EOF'
[daemon]
WaylandEnable=true
AutomaticLoginEnable=false
AutomaticLogin=radiateos
TimedLoginEnable=false
TimedLogin=radiateos
TimedLoginDelay=10

[security]
DisallowTCP=true

[xdmcp]
Enable=false

[chooser]

[debug]
Enable=false
EOF

# Create compositor configuration
log_info "Setting up compositor..."
cat > /usr/local/bin/radiateos-compositor << 'EOF'
#!/bin/bash
# RadiateOS Compositor

# Detect GPU
GPU_VENDOR=$(lspci | grep -i vga | grep -i nvidia > /dev/null && echo "nvidia" || echo "other")

if [ "$GPU_VENDOR" = "nvidia" ]; then
    # NVIDIA optimized compositor
    export __GL_SYNC_TO_VBLANK=1
    export __GL_YIELD="USLEEP"
    export __GL_THREADED_OPTIMIZATIONS=1
    export CLUTTER_VBLANK=TRUE
    
    # Use picom for X11
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        picom --backend glx --vsync --use-damage &
    fi
else
    # Generic compositor
    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        compton --backend glx --vsync opengl-swc &
    fi
fi

# Start window manager
exec mutter --wayland --display-server
EOF

chmod +x /usr/local/bin/radiateos-compositor

# Install additional compositor tools
apt-get install -y picom compton

# Create systemd service
cat > /etc/systemd/system/radiateos-display.service << 'EOF'
[Unit]
Description=RadiateOS Display Server
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/radiateos-session
Restart=on-failure
User=radiateos
Group=radiateos
Environment="HOME=/home/radiateos"

[Install]
WantedBy=graphical.target
EOF

systemctl enable radiateos-display.service

log_info "Display server configuration complete!"
echo "============================================"
echo "Configuration Summary:"
echo "- X11: Configured with NVIDIA support"
echo "- Wayland: Available with XWayland"
echo "- Compositor: Hardware accelerated"
echo "- Display Manager: GDM3"
echo "- Session: Selectable at login"
echo "============================================"