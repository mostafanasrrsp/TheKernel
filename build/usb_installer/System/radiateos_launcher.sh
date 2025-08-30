#!/bin/bash
# RadiateOS Launcher Script
# This script launches RadiateOS in a graphical environment

echo "╔════════════════════════════════════════╗"
echo "║         RadiateOS Boot System          ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Initializing Optical Computing System..."
sleep 1

# Check for Python (for GUI)
if command -v python3 &> /dev/null; then
    python3 /System/radiateos_gui.py
elif command -v python &> /dev/null; then
    python /System/radiateos_gui.py
else
    echo "Starting terminal-based RadiateOS..."
    /System/radiateos_terminal.sh
fi
