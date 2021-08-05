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

namespace Budgie {
	/**
	 * FIXME: we shouldn't be able to create an app from outside of Abomination
	 */
	public class AbominationRunningApp : GLib.Object {
		public ulong id { get; private set; } // Window id
		public string name { get; private set; } // App name
		public DesktopAppInfo? app_info { get; private set; default = null; }
		public string icon { get; private set; } // Icon associated with this app
		public unowned AbominationAppGroup group_object { get; private set; } // Actual AbominationAppGroup object

		private Wnck.Window window; // Window of app
		private Budgie.AppSystem? app_system = null;

		/**
		 * Signals
		 */
		public signal void icon_changed(string icon_name);
		public signal void name_changed(string name);

		public AbominationRunningApp(Budgie.AppSystem app_system, Wnck.Window window, AbominationAppGroup group) {
			this.set_window(window);

			if (this.window != null) {
				this.id = this.window.get_xid();
				this.name = this.window.get_name();
				this.group_object = group;
			}

			this.app_system = app_system;

			debug("Created app: %s", this.name);

			this.update_group();
		}

		/**
		 * invalid_window will check if the provided window is our current window
		 * If the provided window is our current window, update to any new window in the class group, update our name, etc.
		 */
		public void invalidate_window(Wnck.Window window) {
			if (this.window == null || window == null) {
				return;
			}

			if (window.get_xid() == this.window.get_xid()) { // The window provided matches ours
				this.window = null; // Set to null

				bool found_new_window = false;
				List<weak Wnck.Window> class_windows = this.group_object.get_windows();

				if (class_windows.length() > 0) { // If we have windows
					class_windows.foreach((other_window) => {
						if (other_window.get_state() != Wnck.WindowState.SKIP_TASKLIST) { // If this window shouldn't be skipped
							this.window = other_window;
							found_new_window = true;
							return;
						}
					});
				}

				if (found_new_window && this.window != null) { // If we found a new window replacement
					this.set_window(this.window); // Set our bindings
				} else if (!found_new_window && this.app_info != null) { // If we didn't find the new window but we at least have the DesktopAppInfo
					this.name = this.app_info.get_display_name(); // Just fallback to the DesktopAppInfo display name
				}
			}
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
				this.update_group();
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

			this.window.name_changed.connect(() => {
				this.update_name();
			});

			this.window.state_changed.connect(() => {
				this.update_name();
			});
		}

		/**
		 * update_group will update our group
		 */
		private void update_group() {
			if (this.window == null) { // Window no longer valid
				return;
			}

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
