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
	* Default width for an OSD notification
	*/
	public const int OSD_SIZE = 350;

	/**
	* How long before the visible OSD expires, default is 2.5 seconds
	*/
	public const int OSD_EXPIRE_TIME = 2500;

	/**
	* Our name on the session bus. Reserved for Budgie use
	*/
	public const string OSD_DBUS_NAME = "org.budgie_desktop.BudgieOSD";

	/**
	* Unique object path on OSD_DBUS_NAME
	*/
	public const string OSD_DBUS_OBJECT_PATH = "/org/budgie_desktop/BudgieOSD";


	/**
	* The BudgieOSD provides a very simplistic On Screen Display service, complying with the
	* private GNOME Settings Daemon -> GNOME Shell protocol.
	*
	* In short, all elements of the permanently present window should be able to hide or show
	* depending on the updated ShowOSD message, including support for a progress bar (level),
	* icon, optional label.
	*
	* This OSD is used by gnome-settings-daemon to portray special events, such as brightness/volume
	* changes, physical volume changes (disk eject/mount), etc. This special window should remain
	* above all other windows and be non-interactive, allowing unobtrosive overlay of information
	* even in full screen movies and games.
	*
	* Each request to ShowOSD will reset the expiration timeout for the OSD's current visibility,
	* meaning subsequent requests to the OSD will keep it on screen in a natural fashion, allowing
	* users to "hold down" the volume change buttons, for example.
	*/
	[GtkTemplate (ui="/com/solus-project/budgie/daemon/osd.ui")]
	public class OSD : Gtk.Window {
		/**
		* Main text display
		*/
		[GtkChild]
		private Gtk.Label label_title;

		/**
		* Main display image. Prefer symbolic icons!
		*/
		[GtkChild]
		private Gtk.Image image_icon;

		/**
		* Optional progressbar
		*/
		[GtkChild]
		public Gtk.ProgressBar progressbar;

		/**
		* Track the primary monitor to show on
		*/
		private Gdk.Monitor primary_monitor;

		/**
		* Current text to display. NULL hides the widget.
		*/
		public string? osd_title {
			public set {
				string? r = value;
				if (r == null) {
					label_title.set_visible(false);
				} else {
					label_title.set_visible(true);
					label_title.set_markup(r);
				}
			}
			public owned get {
				if (!label_title.get_visible()) {
					return null;
				}
				return label_title.get_label();
			}
		}

		/**
		* Current icon to display. NULL hides the widget
		*/
		public string? osd_icon {
			public set {
				string? r = value;
				if (r == null) {
					image_icon.set_visible(false);
				} else {
					image_icon.set_from_icon_name(r, Gtk.IconSize.INVALID);
					image_icon.pixel_size = 48;
					image_icon.set_visible(true);
				}
			}
			public owned get {
				if (!image_icon.get_visible()) {
					return null;
				}
				string ret;
				Gtk.IconSize _icon_size;
				image_icon.get_icon_name(out ret, out _icon_size);
				return ret;
			}
		}

		/**
		* Construct a new BudgieOSD widget
		*/
		public OSD() {
			Object(type: Gtk.WindowType.POPUP, type_hint: Gdk.WindowTypeHint.NOTIFICATION);
			/* Skip everything, appear above all else, everywhere. */
			resizable = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			set_decorated(false);
			set_keep_above(true);
			stick();

			/* Set up an RGBA map for transparency styling */
			Gdk.Visual? vis = screen.get_rgba_visual();
			if (vis != null) {
				this.set_visual(vis);
			}

			/* Update the primary monitor notion */
			screen.monitors_changed.connect(on_monitors_changed);

			/* Set up size */
			set_default_size(OSD_SIZE, -1);
			realize();

			osd_title = null;
			osd_icon = null;

			get_child().show_all();
			set_visible(false);

			/* Get everything into position prior to the first showing */
			on_monitors_changed();
		}

		/**
		* Monitors changed, find out the primary monitor, and schedule move of OSD
		*/
		private void on_monitors_changed() {
			primary_monitor = screen.get_display().get_primary_monitor();
			move_osd();
		}

		/**
		* Move the OSD into the correct position
		*/
		public void move_osd() {
			/* Find the primary monitor bounds */
			Gdk.Rectangle bounds = primary_monitor.get_geometry();
			Gtk.Allocation alloc;

			get_child().get_allocation(out alloc);

			/* For now just center it */
			int x = bounds.x + ((bounds.width / 2) - (alloc.width / 2));
			int y = bounds.y + ((int)(bounds.height * 0.85));
			move(x, y);
		}
	}

	/**
	* BudgieOSDManager is responsible for managing the BudgieOSD over d-bus, receiving
	* requests, for example, from budgie-wm
	*/
	[DBus (name="org.budgie_desktop.BudgieOSD")]
	public class OSDManager {
		private OSD? osd_window = null;
		private uint32 expire_timeout = 0;

		[DBus (visible=false)]
		public OSDManager() {
			osd_window = new OSD();
		}

		/**
		* Own the OSD_DBUS_NAME
		*/
		[DBus (visible=false)]
		public void setup_dbus(bool replace) {
			var flags = BusNameOwnerFlags.ALLOW_REPLACEMENT;
			if (replace) {
				flags |= BusNameOwnerFlags.REPLACE;
			}
			Bus.own_name(BusType.SESSION, Budgie.OSD_DBUS_NAME, flags,
				on_bus_acquired, ()=> {}, Budgie.DaemonNameLost);
		}

		/**
		* Acquired OSD_DBUS_NAME, register ourselves on the bus
		*/
		private void on_bus_acquired(DBusConnection conn) {
			try {
				conn.register_object(Budgie.OSD_DBUS_OBJECT_PATH, this);
			} catch (Error e) {
				stderr.printf("Error registering BudgieOSD: %s\n", e.message);
			}
			Budgie.setup = true;
		}

		/**
		* Show the OSD on screen with the given parameters:
		* icon: string Icon-name to use
		* label: string Text to display, if any
		* level: Progress-level to display in the OSD (double or int32 depending on gsd release)
		* monitor: int32 The monitor to display the OSD on (currently ignored)
		*/
		public void ShowOSD(HashTable<string,Variant> params) throws DBusError, IOError {
			string? icon_name = null;
			string? label = null;

			if (params.contains("icon")) {
				icon_name = params.lookup("icon").get_string();
			}
			if (params.contains("label")) {
				label = params.lookup("label").get_string();
			}

			double prog_value = -1;

			if (params.contains("level")) {
	#if USE_GSD_DOUBLES
				prog_value = params.lookup("level").get_double();
	#else
				int32 prog_int = params.lookup("level").get_int32();
				prog_value = prog_int.clamp(0, 100) / 100.0;
	#endif
			}

			/* Update the OSD accordingly */
			osd_window.osd_title = label;
			osd_window.osd_icon = icon_name;

			if (prog_value < 0) {
				osd_window.progressbar.set_visible(false);
			} else {
				osd_window.progressbar.set_fraction(prog_value);
				osd_window.progressbar.set_visible(true);
			}

			this.reset_osd_expire(OSD_EXPIRE_TIME);
		}

		/**
		* Reset and update the expiration for the OSD timeout
		*/
		private void reset_osd_expire(int timeout_length) {
			if (expire_timeout > 0) {
				Source.remove(expire_timeout);
				expire_timeout = 0;
			}
			if (!osd_window.get_visible()) {
				osd_window.move_osd();
			}
			osd_window.show();
			expire_timeout = Timeout.add(timeout_length, this.osd_expire);
		}

		/**
		* Expiration timeout was met, so hide the OSD Window
		*/
		private bool osd_expire() {
			if (expire_timeout == 0) {
				return false;
			}
			osd_window.hide();
			expire_timeout = 0;
			return false;
		}
	}
}
