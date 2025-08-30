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
