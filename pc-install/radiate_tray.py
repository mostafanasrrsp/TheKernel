#!/usr/bin/env python3
import os
import subprocess
import sys

try:
    import gi  # type: ignore
    gi.require_version('Gtk', '3.0')
    gi.require_version('AppIndicator3', '0.1')
    from gi.repository import Gtk, AppIndicator3, GLib  # type: ignore
except Exception as e:
    print("AppIndicator not available:", e, file=sys.stderr)
    sys.exit(0)

APP_ID = 'radiateos.gpu.tray'
ICON_PATH = '/opt/radiateos-pc/tools/radiate_tray.svg'


def run_cmd(cmd):
    try:
        subprocess.run(cmd, check=True)
    except Exception as e:
        print(f"Command failed: {' '.join(cmd)} -> {e}")


def in_terminal(cmd):
    term = os.environ.get('XTERM', 'x-terminal-emulator')
    full = [term, '-e', 'bash', '-lc', cmd]
    run_cmd(full)


class Tray:
    def __init__(self):
        self.ind = AppIndicator3.Indicator.new(APP_ID, ICON_PATH, AppIndicator3.IndicatorCategory.APPLICATION_STATUS)
        self.ind.set_status(AppIndicator3.IndicatorStatus.ACTIVE)
        self.ind.set_title('RadiateOS GPU')
        self.menu = Gtk.Menu()

        # Status
        item_status = Gtk.MenuItem(label='Show Status')
        item_status.connect('activate', self.on_status)
        self.menu.append(item_status)

        # Modes submenu
        submenu_mode = Gtk.Menu()
        item_mode = Gtk.MenuItem(label='GPU Mode')
        item_mode.set_submenu(submenu_mode)
        for mode, label in [
            ('on_demand', 'On-Demand (Hybrid)'),
            ('nvidia_only', 'NVIDIA Only'),
            ('intel_only', 'Integrated Only'),
            ('auto', 'Auto (Default)')
        ]:
            mi = Gtk.MenuItem(label=label)
            mi.connect('activate', self.on_mode, mode)
            submenu_mode.append(mi)
        self.menu.append(item_mode)

        # Power submenu
        submenu_power = Gtk.Menu()
        item_power = Gtk.MenuItem(label='Power Profile')
        item_power.set_submenu(submenu_power)
        for prof, label in [
            ('throttled', 'Throttled (Cool)'),
            ('balanced', 'Balanced (Default)'),
            ('performance', 'Performance (Hot)')
        ]:
            mi = Gtk.MenuItem(label=label)
            mi.connect('activate', self.on_power, prof)
            submenu_power.append(mi)
        self.menu.append(item_power)

        self.menu.append(Gtk.SeparatorMenuItem())

        # Quit
        item_quit = Gtk.MenuItem(label='Quit')
        item_quit.connect('activate', self.on_quit)
        self.menu.append(item_quit)

        self.menu.show_all()
        self.ind.set_menu(self.menu)

    def on_status(self, _):
        in_terminal('radiate-gpu status; echo; read -n1 -rsp "Press any key to close..."')

    def on_mode(self, _, mode):
        # Use pkexec for elevation (graphical prompt)
        in_terminal(f'pkexec radiate-gpu mode {mode} || sudo radiate-gpu mode {mode}; echo; read -n1 -rsp "Press any key to close..."')

    def on_power(self, _, profile):
        in_terminal(f'pkexec radiate-gpu power {profile} || sudo radiate-gpu power {profile}; echo; read -n1 -rsp "Press any key to close..."')

    def on_quit(self, _):
        Gtk.main_quit()


def main():
    Tray()
    GLib.set_application_name('RadiateOS GPU Tray')
    Gtk.main()


if __name__ == '__main__':
    main()

