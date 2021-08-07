/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie.Abomination {
	/**
	 * RunningApp is our wrapper for Wnck.Window with information
	 * needed by Budgie components.
	 */
	public class RunningApp : GLib.Object {
		public ulong id { get; private set; } // Window id
		public string name { get; private set; } // App name
		public DesktopAppInfo? app_info { get; private set; default = null; }
		public string icon { get; private set; } // Icon associated with this app
		public unowned AppGroup group_object { get; private set; } // Actual AppGroup object

		private Wnck.Window window; // Window of app
		private Budgie.AppSystem? app_system = null;

		/**
		 * Signals
		 */
		public signal void icon_changed(string icon_name);
		public signal void name_changed(string name);

		internal RunningApp(Budgie.AppSystem app_system, Wnck.Window window, AppGroup group) {
			this.set_window(window);

			this.id = this.window.get_xid();
			this.name = this.window.get_name();
			this.group_object = group;

			this.app_system = app_system;
			this.update_app_info();

			debug("Created app: %s", this.name);
		}

		public string get_group_name() {
			return this.group_object.get_name();
		}

		public Wnck.Window get_window() {
			return this.window;
		}

		/**
		 * set_window will handle setting our window and its bindings
		 */
		private void set_window(Wnck.Window window) {
			if (window == null) { // Window provided is null
				return;
			}

			this.window = window;
			this.update_icon();
			this.update_name();

			this.window.class_changed.connect(() => {
				this.update_app_info();
				this.update_icon();
				this.update_name();
			});

			this.window.icon_changed.connect(() => {
				string old_icon = this.icon;
				this.update_icon();

				if (this.icon != old_icon) { // Actually changed
					this.icon_changed(this.icon);
				}
			});

			this.window.name_changed.connect(() => this.update_name());
			this.window.state_changed.connect(() => this.update_name());
		}

		/**
		 * update_app_info will update our app information based on the window
		 * associated with the app.
		 */
		private void update_app_info() {
			this.app_info = this.app_system.query_window(this.window);
		}

		/**
		 * update_icon will update our icon
		 */
		private void update_icon() {
			if (this.app_info != null && this.app_info.has_key("Icon")) { // Got app info
				this.icon = this.app_info.get_string("Icon");
			}
		}

		/**
		 * update_name will update the window name
		 */
		private void update_name() {
			string old_name = this.name;

			if (this.window != null) {
				this.name = this.window.get_name();

				if (this.name != old_name) { // Actually changed
					this.name_changed(this.name);
				}
			}
		}
	}
}
