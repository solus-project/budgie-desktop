/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	* Our name on the session bus. Reserved for Budgie use
	*/
	public const string MENU_DBUS_NAME = "org.budgie_desktop.MenuManager";

	/**
	* Unique object path on OSD_DBUS_NAME
	*/
	public const string MENU_DBUS_OBJECT_PATH = "/org/budgie_desktop/MenuManager";


	/**
	* BudgieMenuManager is responsible for managing the right click menus of
	* the budgie desktop over dbus, so that GTK+ isn't used inside the WM process
	*/
	[DBus (name="org.budgie_desktop.MenuManager")]
	public class MenuManager {
		private Gtk.Menu? desktop_menu = null;
		private unowned Wnck.Window? active_window = null;
		private Wnck.ActionMenu? action_menu = null;
		private uint32 xid = 0;

		[DBus (visible=false)]
		public MenuManager() {
			init_desktop_menu();
		}

		/**
		* Construct the root level desktop menu (right click on wallpaper
		*/
		private void init_desktop_menu() {
			desktop_menu = new Gtk.Menu();
			desktop_menu.show();
			var item = new Gtk.MenuItem.with_label(_("Budgie Desktop Settings"));
			item.activate.connect(budgie_activate);
			item.show();
			desktop_menu.append(item);

			item = new Gtk.MenuItem.with_label(_("System Settings"));
			item.activate.connect(settings_activate);
			item.show();
			desktop_menu.append(item);

			/* Visibility test will now fail so we get first show working fine */
			desktop_menu.hide();
		}

		/**
		* Launch a .desktop name in a fail safe fashion
		*/
		private void launch_desktop_name(string desktop_name) {
			try {
				var info = new DesktopAppInfo(desktop_name);
				if (info != null) {
					info.launch(null, null);
				}
			} catch (Error e) {
				warning("Unable to launch %s: %s", desktop_name, e.message);
			}
		}

		/**
		* Launch Budgie Desktop Settings
		*/
		private void budgie_activate() {
			launch_desktop_name("budgie-desktop-settings.desktop");
		}

		/**
		* Launch main settings (gnome control center)
		*/
		private void settings_activate() {
			launch_desktop_name("gnome-control-center.desktop");
		}

		/**
		* Own the MENU_DBUS_NAME
		*/
		[DBus (visible=false)]
		public void setup_dbus(bool replace) {
			var flags = BusNameOwnerFlags.ALLOW_REPLACEMENT;
			if (replace) {
				flags |= BusNameOwnerFlags.REPLACE;
			}
			Bus.own_name(BusType.SESSION, Budgie.MENU_DBUS_NAME, flags,
				on_bus_acquired, ()=> {}, Budgie.DaemonNameLost);
		}

		/**
		* Acquired MENU_DBUS_NAME, register ourselves on the bus
		*/
		private void on_bus_acquired(DBusConnection conn) {
			try {
				conn.register_object(Budgie.MENU_DBUS_OBJECT_PATH, this);
			} catch (Error e) {
				stderr.printf("Error registering BudgieMenuManager: %s\n", e.message);
			}
			Budgie.setup = true;
		}

		/**
		* We've been asked to display the root menu for the desktop itself,
		* which contains actions for launching the settings, etc.
		*/
		public void ShowDesktopMenu(uint button, uint32 timestamp) throws DBusError, IOError {
			Idle.add(() => {
				if (desktop_menu.get_visible()) {
					desktop_menu.hide();
				} else {
					desktop_menu.popup(null, null, null, button, timestamp == 0 ? Gdk.CURRENT_TIME : timestamp);
				}
				return false;
			});
		}

		/**
		* Show a window menu for the given window ID
		*/
		public void ShowWindowMenu(uint32 xid, uint button, uint32 timestamp) throws DBusError, IOError {
			active_window = Wnck.Window.get(xid);
			if (active_window == null) {
				return;
			}
			action_menu = new Wnck.ActionMenu(active_window);
			action_menu.popup(null, null, null, 3, Gdk.CURRENT_TIME);
			this.xid = xid;
		}
	}
}
