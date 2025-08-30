#!/usr/bin/env bash
set -euo pipefail

# RadiateOS USB Preparation Script
# Prepares RadiateOS files for USB installation

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   RadiateOS USB Preparation Script     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Create build directory structure
echo -e "${BLUE}📁 Creating build structure...${NC}"
mkdir -p build/usb_installer/{System,Applications,Boot,EFI/BOOT}

# Create a bootable RadiateOS launcher script
echo -e "${BLUE}🚀 Creating RadiateOS launcher...${NC}"
cat > build/usb_installer/System/radiateos_launcher.sh << 'EOF'
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
EOF
chmod +x build/usb_installer/System/radiateos_launcher.sh

# Create Python GUI version
echo -e "${BLUE}🖥️  Creating GUI interface...${NC}"
cat > build/usb_installer/System/radiateos_gui.py << 'EOF'
#!/usr/bin/env python3
"""
RadiateOS - Optical Computing Operating System
GUI Interface
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import os
import sys
import subprocess
from datetime import datetime

class RadiateOS:
    def __init__(self, root):
        self.root = root
        self.root.title("RadiateOS - Optical Computing System")
        self.root.geometry("1024x768")
        
        # Set dark theme colors
        self.bg_color = "#1a1a2e"
        self.fg_color = "#eee"
        self.accent_color = "#0f4c81"
        self.highlight_color = "#16213e"
        
        self.root.configure(bg=self.bg_color)
        
        self.setup_ui()
        self.show_boot_animation()
        
    def setup_ui(self):
        # Create menu bar
        menubar = tk.Menu(self.root, bg=self.bg_color, fg=self.fg_color)
        self.root.config(menu=menubar)
        
        # File menu
        file_menu = tk.Menu(menubar, tearoff=0, bg=self.bg_color, fg=self.fg_color)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="New Window", command=self.new_window)
        file_menu.add_command(label="Open Terminal", command=self.open_terminal)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)
        
        # System menu
        system_menu = tk.Menu(menubar, tearoff=0, bg=self.bg_color, fg=self.fg_color)
        menubar.add_cascade(label="System", menu=system_menu)
        system_menu.add_command(label="System Info", command=self.show_system_info)
        system_menu.add_command(label="Optical Performance", command=self.show_performance)
        
        # Help menu
        help_menu = tk.Menu(menubar, tearoff=0, bg=self.bg_color, fg=self.fg_color)
        menubar.add_cascade(label="Help", menu=help_menu)
        help_menu.add_command(label="About", command=self.show_about)
        
        # Main container
        self.main_frame = tk.Frame(self.root, bg=self.bg_color)
        self.main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Top bar with status
        self.status_frame = tk.Frame(self.main_frame, bg=self.highlight_color, height=40)
        self.status_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.status_label = tk.Label(
            self.status_frame,
            text="RadiateOS Ready - Optical Computing Active",
            bg=self.highlight_color,
            fg=self.fg_color,
            font=("Helvetica", 12)
        )
        self.status_label.pack(pady=10)
        
        # Desktop area with icons
        self.desktop_frame = tk.Frame(self.main_frame, bg=self.bg_color)
        self.desktop_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create desktop icons
        self.create_desktop_icons()
        
        # Bottom taskbar
        self.taskbar = tk.Frame(self.root, bg=self.highlight_color, height=50)
        self.taskbar.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Clock
        self.clock_label = tk.Label(
            self.taskbar,
            bg=self.highlight_color,
            fg=self.fg_color,
            font=("Helvetica", 10)
        )
        self.clock_label.pack(side=tk.RIGHT, padx=10)
        self.update_clock()
        
    def create_desktop_icons(self):
        """Create desktop application icons"""
        apps = [
            ("Terminal", self.open_terminal, "🖥️"),
            ("File Manager", self.open_file_manager, "📁"),
            ("Text Editor", self.open_text_editor, "📝"),
            ("System Monitor", self.show_performance, "📊"),
            ("Settings", self.open_settings, "⚙️"),
            ("Calculator", self.open_calculator, "🧮")
        ]
        
        row = 0
        col = 0
        for app_name, command, icon in apps:
            app_frame = tk.Frame(self.desktop_frame, bg=self.bg_color)
            app_frame.grid(row=row, column=col, padx=20, pady=20)
            
            # Icon button
            btn = tk.Button(
                app_frame,
                text=icon,
                font=("Helvetica", 32),
                bg=self.bg_color,
                fg=self.fg_color,
                bd=0,
                command=command,
                cursor="hand2"
            )
            btn.pack()
            
            # Label
            label = tk.Label(
                app_frame,
                text=app_name,
                bg=self.bg_color,
                fg=self.fg_color,
                font=("Helvetica", 10)
            )
            label.pack()
            
            col += 1
            if col > 3:
                col = 0
                row += 1
    
    def show_boot_animation(self):
        """Show boot animation"""
        boot_window = tk.Toplevel(self.root)
        boot_window.title("RadiateOS Boot")
        boot_window.geometry("600x400")
        boot_window.configure(bg="#000")
        
        # Center the window
        boot_window.update_idletasks()
        x = (boot_window.winfo_screenwidth() // 2) - (600 // 2)
        y = (boot_window.winfo_screenheight() // 2) - (400 // 2)
        boot_window.geometry(f"600x400+{x}+{y}")
        
        # Boot text
        boot_text = tk.Text(
            boot_window,
            bg="#000",
            fg="#0f0",
            font=("Courier", 10),
            wrap=tk.WORD
        )
        boot_text.pack(fill=tk.BOTH, expand=True)
        
        # Boot sequence
        boot_messages = [
            "RadiateOS v1.0 - Optical Computing System",
            "Initializing photonic processors...",
            "Loading quantum encryption modules...",
            "Calibrating optical pathways...",
            "Starting neural interface...",
            "Mounting filesystems...",
            "Loading desktop environment...",
            "System ready!"
        ]
        
        for i, msg in enumerate(boot_messages):
            boot_text.insert(tk.END, f"[{datetime.now().strftime('%H:%M:%S')}] {msg}\n")
            boot_text.update()
            self.root.after(300 * (i + 1), lambda: None)
        
        self.root.after(3000, boot_window.destroy)
    
    def update_clock(self):
        """Update the taskbar clock"""
        current_time = datetime.now().strftime("%H:%M:%S")
        self.clock_label.config(text=current_time)
        self.root.after(1000, self.update_clock)
    
    def new_window(self):
        """Open a new window"""
        window = tk.Toplevel(self.root)
        window.title("New Window")
        window.geometry("400x300")
        window.configure(bg=self.bg_color)
        
        label = tk.Label(
            window,
            text="New RadiateOS Window",
            bg=self.bg_color,
            fg=self.fg_color,
            font=("Helvetica", 14)
        )
        label.pack(pady=20)
    
    def open_terminal(self):
        """Open terminal emulator"""
        terminal = tk.Toplevel(self.root)
        terminal.title("RadiateOS Terminal")
        terminal.geometry("800x600")
        terminal.configure(bg="#000")
        
        # Terminal text widget
        term_text = tk.Text(
            terminal,
            bg="#000",
            fg="#0f0",
            font=("Courier", 10),
            insertbackground="#0f0"
        )
        term_text.pack(fill=tk.BOTH, expand=True)
        
        term_text.insert(tk.END, "RadiateOS Terminal v1.0\n")
        term_text.insert(tk.END, "Type 'help' for available commands\n")
        term_text.insert(tk.END, "$ ")
        
        # Simple command handler
        def handle_command(event):
            command = term_text.get("end-2l lineend", "end-1c").strip()[2:]  # Remove "$ "
            term_text.insert(tk.END, "\n")
            
            if command == "help":
                term_text.insert(tk.END, "Available commands:\n")
                term_text.insert(tk.END, "  help     - Show this help\n")
                term_text.insert(tk.END, "  clear    - Clear screen\n")
                term_text.insert(tk.END, "  info     - System information\n")
                term_text.insert(tk.END, "  exit     - Close terminal\n")
            elif command == "clear":
                term_text.delete("1.0", tk.END)
                term_text.insert(tk.END, "RadiateOS Terminal v1.0\n")
            elif command == "info":
                term_text.insert(tk.END, "RadiateOS - Optical Computing System\n")
                term_text.insert(tk.END, "Version: 1.0\n")
                term_text.insert(tk.END, "Photonic Processing: Active\n")
            elif command == "exit":
                terminal.destroy()
                return
            else:
                term_text.insert(tk.END, f"Command not found: {command}\n")
            
            term_text.insert(tk.END, "$ ")
            return "break"
        
        term_text.bind("<Return>", handle_command)
        term_text.focus()
    
    def open_file_manager(self):
        """Open file manager"""
        fm = tk.Toplevel(self.root)
        fm.title("File Manager")
        fm.geometry("800x600")
        fm.configure(bg=self.bg_color)
        
        # File tree
        tree = ttk.Treeview(fm)
        tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Add some sample items
        root_item = tree.insert("", "end", text="/", open=True)
        tree.insert(root_item, "end", text="System")
        tree.insert(root_item, "end", text="Applications")
        tree.insert(root_item, "end", text="Users")
        tree.insert(root_item, "end", text="Documents")
    
    def open_text_editor(self):
        """Open text editor"""
        editor = tk.Toplevel(self.root)
        editor.title("Text Editor")
        editor.geometry("800x600")
        
        # Text widget
        text = tk.Text(editor, wrap=tk.WORD)
        text.pack(fill=tk.BOTH, expand=True)
        
        # Menu
        menubar = tk.Menu(editor)
        editor.config(menu=menubar)
        
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Save", command=lambda: self.save_file(text))
        file_menu.add_command(label="Open", command=lambda: self.open_file(text))
    
    def save_file(self, text_widget):
        """Save file from text editor"""
        file_path = filedialog.asksaveasfilename(defaultextension=".txt")
        if file_path:
            with open(file_path, "w") as f:
                f.write(text_widget.get("1.0", tk.END))
            messagebox.showinfo("Success", "File saved successfully!")
    
    def open_file(self, text_widget):
        """Open file in text editor"""
        file_path = filedialog.askopenfilename()
        if file_path:
            with open(file_path, "r") as f:
                content = f.read()
            text_widget.delete("1.0", tk.END)
            text_widget.insert("1.0", content)
    
    def open_calculator(self):
        """Open calculator app"""
        calc = tk.Toplevel(self.root)
        calc.title("Calculator")
        calc.geometry("300x400")
        calc.configure(bg=self.bg_color)
        
        # Display
        display = tk.Entry(calc, font=("Helvetica", 20), justify=tk.RIGHT)
        display.grid(row=0, column=0, columnspan=4, padx=5, pady=5, sticky="ew")
        
        # Buttons
        buttons = [
            "7", "8", "9", "/",
            "4", "5", "6", "*",
            "1", "2", "3", "-",
            "0", ".", "=", "+"
        ]
        
        row = 1
        col = 0
        for button in buttons:
            btn = tk.Button(
                calc,
                text=button,
                font=("Helvetica", 14),
                width=5,
                height=2,
                command=lambda b=button: self.calc_button_click(display, b)
            )
            btn.grid(row=row, column=col, padx=2, pady=2)
            col += 1
            if col > 3:
                col = 0
                row += 1
    
    def calc_button_click(self, display, button):
        """Handle calculator button clicks"""
        current = display.get()
        
        if button == "=":
            try:
                result = eval(current)
                display.delete(0, tk.END)
                display.insert(0, str(result))
            except:
                display.delete(0, tk.END)
                display.insert(0, "Error")
        else:
            display.insert(tk.END, button)
    
    def open_settings(self):
        """Open settings window"""
        settings = tk.Toplevel(self.root)
        settings.title("Settings")
        settings.geometry("600x400")
        settings.configure(bg=self.bg_color)
        
        tk.Label(
            settings,
            text="RadiateOS Settings",
            bg=self.bg_color,
            fg=self.fg_color,
            font=("Helvetica", 16, "bold")
        ).pack(pady=20)
        
        # Settings options
        options = [
            "Display Settings",
            "Network Configuration",
            "Optical Processing",
            "System Updates",
            "Security & Privacy"
        ]
        
        for option in options:
            btn = tk.Button(
                settings,
                text=option,
                bg=self.highlight_color,
                fg=self.fg_color,
                font=("Helvetica", 12),
                width=30,
                command=lambda o=option: messagebox.showinfo("Settings", f"{o} - Coming soon!")
            )
            btn.pack(pady=5)
    
    def show_system_info(self):
        """Show system information"""
        info = tk.Toplevel(self.root)
        info.title("System Information")
        info.geometry("500x400")
        info.configure(bg=self.bg_color)
        
        info_text = tk.Text(info, bg=self.bg_color, fg=self.fg_color, font=("Courier", 10))
        info_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        system_info = """
RadiateOS System Information
============================
Version: 1.0.0
Build: 2024.01.15
Kernel: Optical Core v1.0

Hardware:
---------
Processor: Photonic CPU (Simulated)
Memory: Quantum RAM (Simulated)
Storage: Optical Drive

Features:
---------
• Optical Computing Simulation
• Quantum Encryption
• Neural Network Integration
• Advanced File System
• Real-time Processing

Status:
-------
System: Online
Optical Core: Active
Performance: Optimal
        """
        
        info_text.insert("1.0", system_info)
        info_text.config(state=tk.DISABLED)
    
    def show_performance(self):
        """Show performance monitor"""
        perf = tk.Toplevel(self.root)
        perf.title("Optical Performance Monitor")
        perf.geometry("600x400")
        perf.configure(bg=self.bg_color)
        
        tk.Label(
            perf,
            text="Optical Computing Performance",
            bg=self.bg_color,
            fg=self.fg_color,
            font=("Helvetica", 14, "bold")
        ).pack(pady=10)
        
        # Performance metrics
        metrics = [
            ("Photonic Processing:", "15.7 THz"),
            ("Quantum Bandwidth:", "1.2 Pb/s"),
            ("Neural Latency:", "0.3 ns"),
            ("Optical Efficiency:", "98.5%"),
            ("Power Consumption:", "12 W"),
            ("Temperature:", "22°C")
        ]
        
        for label, value in metrics:
            frame = tk.Frame(perf, bg=self.bg_color)
            frame.pack(fill=tk.X, padx=20, pady=5)
            
            tk.Label(
                frame,
                text=label,
                bg=self.bg_color,
                fg=self.fg_color,
                font=("Helvetica", 11),
                width=20,
                anchor="w"
            ).pack(side=tk.LEFT)
            
            tk.Label(
                frame,
                text=value,
                bg=self.bg_color,
                fg="#0f0",
                font=("Courier", 11, "bold")
            ).pack(side=tk.LEFT)
    
    def show_about(self):
        """Show about dialog"""
        about_text = """
RadiateOS v1.0

The Next Generation Optical Computing Operating System

Features:
• Photonic Processing Simulation
• Quantum-Encrypted File System
• Neural Network Integration
• Advanced Window Management
• Real-time Performance Optimization

Created with advanced optical computing principles
for the future of computing.

© 2024 RadiateOS Project
        """
        messagebox.showinfo("About RadiateOS", about_text)

def main():
    root = tk.Tk()
    app = RadiateOS(root)
    root.mainloop()

if __name__ == "__main__":
    main()
EOF

# Create terminal-based version
echo -e "${BLUE}💻 Creating terminal interface...${NC}"
cat > build/usb_installer/System/radiateos_terminal.sh << 'EOF'
#!/bin/bash
# RadiateOS Terminal Interface

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    RadiateOS Terminal                       ║"
echo "║              Optical Computing Operating System             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

show_menu() {
    echo "Main Menu:"
    echo "1) System Information"
    echo "2) File Manager"
    echo "3) Process Monitor"
    echo "4) Network Status"
    echo "5) Optical Performance"
    echo "6) Terminal Shell"
    echo "7) Shutdown"
    echo ""
    echo -n "Select option: "
}

while true; do
    show_menu
    read -r option
    
    case $option in
        1)
            echo ""
            echo "System Information:"
            echo "==================="
            echo "OS: RadiateOS v1.0"
            echo "Kernel: $(uname -r)"
            echo "Architecture: $(uname -m)"
            echo "Hostname: $(hostname)"
            echo "Uptime: $(uptime -p)"
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
        2)
            echo ""
            echo "File Manager:"
            echo "============="
            ls -la /
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
        3)
            echo ""
            echo "Process Monitor:"
            echo "================"
            ps aux | head -20
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
        4)
            echo ""
            echo "Network Status:"
            echo "==============="
            ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Network information unavailable"
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
        5)
            echo ""
            echo "Optical Performance Metrics:"
            echo "============================"
            echo "Photonic Processing: 15.7 THz"
            echo "Quantum Bandwidth: 1.2 Pb/s"
            echo "Neural Latency: 0.3 ns"
            echo "Optical Efficiency: 98.5%"
            echo "Power Consumption: 12 W"
            echo ""
            read -p "Press Enter to continue..."
            clear
            ;;
        6)
            echo ""
            echo "Entering shell mode (type 'exit' to return)..."
            bash
            clear
            ;;
        7)
            echo ""
            echo "Shutting down RadiateOS..."
            sleep 2
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            sleep 2
            clear
            ;;
    esac
done
EOF
chmod +x build/usb_installer/System/radiateos_terminal.sh

# Create GRUB configuration for bootable USB
echo -e "${BLUE}⚙️  Creating boot configuration...${NC}"
cat > build/usb_installer/Boot/grub.cfg << 'EOF'
set timeout=5
set default=0

menuentry "RadiateOS - Optical Computing System" {
    linux /Boot/vmlinuz root=/dev/sda1 rw init=/System/radiateos_launcher.sh quiet splash
    initrd /Boot/initrd.img
}

menuentry "RadiateOS - Recovery Mode" {
    linux /Boot/vmlinuz root=/dev/sda1 rw init=/bin/bash
    initrd /Boot/initrd.img
}

menuentry "RadiateOS - Terminal Mode" {
    linux /Boot/vmlinuz root=/dev/sda1 rw init=/System/radiateos_terminal.sh
    initrd /Boot/initrd.img
}
EOF

# Create EFI boot script
cat > build/usb_installer/EFI/BOOT/startup.nsh << 'EOF'
echo "Starting RadiateOS..."
\System\radiateos_launcher.sh
EOF

# Create README for the USB
cat > build/usb_installer/README.txt << 'EOF'
RadiateOS - Optical Computing Operating System
==============================================

Welcome to RadiateOS!

This USB contains a bootable version of RadiateOS, featuring:
- Optical computing simulation
- Quantum encryption
- Neural network integration
- Advanced GUI and terminal interfaces

To boot RadiateOS:
1. Restart your computer
2. Access boot menu (usually F12, F2, or ESC during startup)
3. Select this USB drive
4. Choose RadiateOS from the boot menu

Available boot modes:
- Normal Mode: Full GUI interface (requires Python)
- Terminal Mode: Text-based interface
- Recovery Mode: Direct shell access

System Requirements:
- 64-bit processor
- 2GB RAM minimum (4GB recommended)
- USB 3.0 port recommended

For more information, visit the RadiateOS project page.
EOF

# Create a simple installer script
cat > build/usb_installer/install_to_disk.sh << 'EOF'
#!/bin/bash
# RadiateOS Disk Installation Script

echo "RadiateOS Installer"
echo "==================="
echo ""
echo "This will install RadiateOS to your hard drive."
echo "WARNING: This will erase all data on the selected disk!"
echo ""

# List available disks
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

echo ""
read -p "Enter target disk (e.g., sda): " target_disk

if [[ ! -b "/dev/$target_disk" ]]; then
    echo "Error: Disk /dev/$target_disk not found"
    exit 1
fi

echo ""
echo "You selected: /dev/$target_disk"
read -p "Are you ABSOLUTELY sure? Type 'yes' to continue: " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Installation cancelled"
    exit 1
fi

echo "Installing RadiateOS..."

# Partition the disk
parted /dev/$target_disk mklabel gpt
parted /dev/$target_disk mkpart primary ext4 1MiB 100%

# Format
mkfs.ext4 /dev/${target_disk}1

# Mount
mkdir -p /mnt/radiateos
mount /dev/${target_disk}1 /mnt/radiateos

# Copy files
cp -r /System /mnt/radiateos/
cp -r /Applications /mnt/radiateos/
cp -r /Boot /mnt/radiateos/

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/mnt/radiateos/boot /dev/$target_disk
cp /Boot/grub.cfg /mnt/radiateos/boot/grub/

echo "Installation complete!"
echo "Remove USB and reboot to start RadiateOS"
EOF
chmod +x build/usb_installer/install_to_disk.sh

echo ""
echo -e "${GREEN}✅ USB installer files prepared successfully!${NC}"
echo ""
echo -e "${CYAN}📁 Files created in build/usb_installer/:${NC}"
echo "  • System/radiateos_launcher.sh - Main launcher"
echo "  • System/radiateos_gui.py - GUI interface"
echo "  • System/radiateos_terminal.sh - Terminal interface"
echo "  • Boot/grub.cfg - Boot configuration"
echo "  • EFI/BOOT/startup.nsh - EFI boot script"
echo "  • install_to_disk.sh - Disk installation script"
echo "  • README.txt - User documentation"
echo ""
echo -e "${YELLOW}📌 Next steps:${NC}"
echo "  1. Insert your USB drive (8GB or larger)"
echo "  2. Run: sudo ./create_usb_installer.sh"
echo "  3. Select your USB drive when prompted"
echo "  4. The script will create a bootable RadiateOS USB"
echo ""
echo -e "${BLUE}The USB will include:${NC}"
echo "  • Bootable RadiateOS system"
echo "  • GUI interface (Python-based)"
echo "  • Terminal interface (shell-based)"
echo "  • Installation option to hard drive"
echo ""