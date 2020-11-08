/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	 * Abomination is our application state tracking manager
	 */
	public class Abomination : GLib.Object {
		private Budgie.AppSystem app_system = new Budgie.AppSystem();
		private Settings? color_settings = new Settings("org.gnome.settings-daemon.plugins.color");
		private Settings? wm_settings = new Settings("com.solus-project.budgie-wm");
		private bool original_night_light_setting = false;
		private bool should_disable_on_fullscreen = false;
		private Wnck.Screen screen = Wnck.Screen.get_default();

		// fullscreen_windows is a list of fullscreen windows based on their name and respective Wnck.Window
		public HashTable<string?,Wnck.Window?> fullscreen_windows = new HashTable<string?,Wnck.Window?>(str_hash, str_equal);
		// running_apps is a list of running apps based on the group name and AbominationRunningApp
		public HashTable<string?,Array<AbominationRunningApp>?> running_apps = new HashTable<string?,Array<AbominationRunningApp>?>(str_hash, str_equal);
		// running_apps_ids is a list of apps based on the window id and AbominationRunningApp
		public HashTable<ulong?,AbominationRunningApp?> running_apps_id = new HashTable<ulong?,AbominationRunningApp?>(int_hash, int_equal);

		/**
		 * Signals
		 */
		public signal void added_group(string group);
		public signal void removed_group(string group);
		public signal void added_app(string group, AbominationRunningApp app);
		public signal void removed_app(string group, AbominationRunningApp app);

		public Abomination() {
			if (color_settings != null) { // gsd colors plugin schema defined
				update_night_light_value();

				color_settings.changed["night-light-enabled"].connect(() => {
					if (fullscreen_windows.size() == 0) { // If we have no currently fullscreen windows
						update_night_light_value(); // Update. We do this to ignore false positives.
					}
				});
			}

			if (wm_settings != null) {
				update_should_disable_value();

				wm_settings.changed["disable-night-light-on-fullscreen"].connect(() => {
					update_should_disable_value();
				});
			}

			screen.class_group_closed.connect((group) => { // On group closed
				string group_name = group.get_name(); // Get the class name

				if (group_name != null) {
					group_name = group_name.down();

					Array<AbominationRunningApp> group_apps = running_apps.get(group_name); // Get the apps associated with the group name

					if ((group_apps != null) && (group_apps.length > 0)) { // If there are apps (and this exists)
						for (int i = 0; i < group_apps.length; i++) {
							AbominationRunningApp app = group_apps.index(i);
							running_apps_id.steal(app.id); // Remove from running_apps_id
						}

						running_apps.steal(group_name); // Remove group from running_apps
					}
				}
			});

			screen.window_opened.connect(add_app);
			screen.window_closed.connect(remove_app);

			screen.get_windows().foreach((window) => { // Init all our current running windows
				add_app(window);
			});
		}

		/**
		 * add_app will add a running application based on the provided window
		 */
		public void add_app(Wnck.Window window) {
			if (is_disallowed_window_type(window)) { // Disallowed type
				return;
			}

			if (window.is_skip_pager() || window.is_skip_tasklist()) { // Skip pager or tasklist
				return;
			}

			AbominationRunningApp app = new AbominationRunningApp(app_system, window); // Create an abomination app

			if (app == null || app.group == null) { // Shouldn't be the case, fail immediately
				return;
			}

			Array<AbominationRunningApp>? group_apps = running_apps.get(app.group);

			bool no_group_yet = false;

			if (group_apps == null) { // Not defined group apps
				group_apps = new Array<AbominationRunningApp>();
				running_apps.insert(app.group, group_apps);
				no_group_yet = true;
			}

			group_apps.append_val(app); // Append the app
			running_apps_id.insert(app.id, app); // Append the app based on id
			added_app(app.group, app);

			if (no_group_yet) {
				added_group(app.group); // Call that we added the group
			}

			app.class_changed.connect((old_class_name, new_class) => {
				rename_group(old_class_name, new_class); // Rename the class
			});

			app.window.state_changed.connect((changed, new_state) => {
				if (Wnck.WindowState.FULLSCREEN in changed) {
					if (new_state == Wnck.WindowState.FULLSCREEN) {
						fullscreen_windows.insert(window.get_name(), window); // Add to fullscreen_windows
						toggle_night_light(false); // Toggle the night light off if possible
					} else {
						fullscreen_windows.steal(window.get_name()); // Remove from fullscreen_windows
						toggle_night_light(true); // Toggle the night light back on if possible
					}
				}
			});
		}

		// is_disallowed_window_type will check if this specified window is a disallowed type
		public bool is_disallowed_window_type(Wnck.Window window) {
			Wnck.WindowType win_type = window.get_window_type(); // Get the window type

			return win_type == Wnck.WindowType.DESKTOP || // Desktop-mode (like Nautilus' Desktop Icons)
				win_type == Wnck.WindowType.DIALOG || // Dialogs
				win_type == Wnck.WindowType.DOCK || // Like Budgie Panel
				win_type == Wnck.WindowType.SPLASHSCREEN || // Splash screens
				win_type == Wnck.WindowType.UTILITY; // Utility like a control on an emulator
		}

		/**
		 * remove_app will remove a running application based on the provided window
		 */
		public void remove_app(Wnck.Window window) {
			ulong id = window.get_xid();
			AbominationRunningApp app = running_apps_id.get(id); // Get the running app

			running_apps_id.steal(id); // Remove from running_apps_id

			if (app == null) {
				return; // app is undefined
			}

			Array<AbominationRunningApp> group_apps = running_apps.get(app.group); // Get apps based on group name

			if (group_apps != null) { // Failed to get the app based on group
				for (int i = 0; i < group_apps.length; i++) {
					if (group_apps.index(i).id == app.id) { // Matches
						group_apps.remove_index(i);
						break;
					}
				}
			}

			removed_app(app.group, app); // Notify that we called remove

			if (group_apps != null) {
				if (group_apps.length == 0) {
					running_apps.steal(app.group); // Dropkick from running apps
					removed_group(app.group); // Removed the group
				}
			} else {
				running_apps.steal(app.group); // Dropkick from running apps
				removed_group(app.group); // Removed the group
			}
		}

		/**
		 * rename_group will rename any associated group based on the old group name
		 * The old group name is determined by current windows associated with the group
		 */
		public void rename_group(string old_group_name, Wnck.ClassGroup group) {
			string group_name = group.get_name();

			// #region Because LibreOffice hates me

			if ((old_group_name.has_prefix("libreoffice-") && !group_name.has_prefix("libreoffice-")) || // libreoffice- change
				(old_group_name.has_prefix("chrome-") && !group_name.has_prefix("chrome-")) // chrome- change
			) {
				return;
			}

			// #endregion

			unowned List<Wnck.Window> windows = group.get_windows();
			if (windows.length() == 0) {
				return; // Has no windows
			}

			Array<AbominationRunningApp> apps_associated_with_group = running_apps.get(old_group_name);

			if (apps_associated_with_group == null || apps_associated_with_group.length == 0) { // if no items added yet
				windows.foreach((window) => { // For each window
					add_app(window); // Add the app (including group)
				});
				return;
			}

			// If there are items
			for (int i = 0; i < apps_associated_with_group.length; i++) {
				AbominationRunningApp app = apps_associated_with_group.index(i);

				if (app.group.has_prefix("libreoffice-")) { // May initially report as soffice or LibreOffice V.v (eg. 6.1)
					group_name = app.group; // Update parent, because it's wrong
				} else {
					app.group = group_name; // Update app
				}
			}

			running_apps.steal(old_group_name); // Remove for "rename"
			removed_group(old_group_name); // Remove the possible old group
			running_apps.insert(group_name, apps_associated_with_group); // Re-add for "rename"
			added_group(group_name);
		}

		/**
		 * toggle_night_light will toggle the state of the night light depending on requested state
		 * If we're disabling, we'll check if there is any items in fullscreen_windows first
		 */
		private void toggle_night_light(bool on_state) {
			if (should_disable_on_fullscreen) {
				if (on_state) { // Attempting to toggle on
					if (fullscreen_windows.size() == 0) { // If we should be turning it on in the first place and there are no fullscreen windows
						color_settings.set_boolean("night-light-enabled", original_night_light_setting); // Revert to original state
					}
				} else { // Attempting to toggle off
					if (fullscreen_windows.size() > 0) { // Fullscreen windows
						color_settings.set_boolean("night-light-enabled", false);
					}
				}
			}
		}

		/**
		 * update_should_disable_value will update our value determininngn if we should disable night light on fullscreen
		 */
		private void update_should_disable_value() {
			if (wm_settings != null) {
				should_disable_on_fullscreen = wm_settings.get_boolean("disable-night-light-on-fullscreen");
			}
		}

		/**
		 * update_night_light_value will update our copy / original night light enabled value
		 */
		private void update_night_light_value() {
			if (color_settings != null) {
				original_night_light_setting = color_settings.get_boolean("night-light-enabled");
			}
		}
	}

	public class AbominationRunningApp : GLib.Object {
		public DesktopAppInfo? app = null;
		public string group; // Group assigned to the app
		public Wnck.ClassGroup group_object; // Actual Wnck.ClassGroup object
		public string icon; // Icon associated with this app
		public string name; // App name
		public ulong id; // Window id
		public Wnck.Window window; // Window of app

		private Budgie.AppSystem? appsys = null;

		/**
		 * Signals
		 */
		public signal void class_changed(string old_class_name, Wnck.ClassGroup class);
		public signal void icon_changed(string icon_name);
		public signal void name_changed(string name);

		public AbominationRunningApp(Budgie.AppSystem app_system, Wnck.Window window) {
			set_window(window);

			if (window != null) {
				id = window.get_xid();
				name = window.get_name();
				group_object = window.get_class_group();
			}

			appsys = app_system;

			update_group();
		}

		/**
		 * invalid_window will check if the provided window is our current window
		 * If the provided window is our current window, update to any new window in the class group, update our name, etc.
		 */
		public void invalidate_window(Wnck.Window other_window) {
			if (window == null || other_window == null) {
				return;
			}

			if (other_window.get_xid() == window.get_xid()) { // The window provided matches ours
				window = null; // Set to null

				bool found_new_window = false;
				unowned List<Wnck.Window> class_windows = group_object.get_windows();

				if (class_windows.length() > 0) { // If we have windows
					class_windows.foreach((class_window) => {
						if (class_window.get_state() != Wnck.WindowState.SKIP_TASKLIST) { // If this window shouldn't be skipped
							window = class_window;
							found_new_window = true;
							return;
						}
					});
				}

				if (found_new_window && window != null) { // If we found a new window replacement
					set_window(window); // Set our bindings
				} else if (!found_new_window && app != null) { // If we didn't find the new window but we at least have the DesktopAppInfo
					name = app.get_display_name(); // Just fallback to the DesktopAppInfo display name
				}
			}
		}

		/**
		 * set_window will handle setting our window and its bindings
		 */
		private void set_window(Wnck.Window new_window) {
			if (new_window == null) { // Window provided is null
				return;
			}

			window = new_window;
			update_icon();
			update_name();

			window.class_changed.connect(() => {
				string old_group = group;

				update_group();
				update_icon();
				update_name();

				if (group != old_group) { // Actually changed
					if (group.has_prefix("chrome-")) {
						return;
					}

					class_changed(old_group, group_object); // Signal that the class changed
				}
			});

			window.icon_changed.connect(() => {
				string old_icon = icon;
				update_icon();

				if (icon != old_icon) { // Actually changed
					icon_changed(icon);
				}
			});

			window.name_changed.connect(() => {
				update_name();
			});

			window.state_changed.connect(() => {
				update_name();
			});
		}

		/**
		 * update_group will update our group. Returns the old group name
		 */
		private void update_group() {
			if (window == null) { // Window no longer valid
				return;
			}

			app = appsys.query_window(window);

			if (app != null) { // Successfully got desktop app info
				group = app.get_id();
			} else if (group_object != null) { // Failed to get desktop app info
				group = group_object.get_name();

				if (group != null) { // Safely got name
					group = group.down();
				}
			} else {
				group = name; // Fallback to using name
			}
		}

		/**
		 * update_icon will update our icon
		 */
		private void update_icon() {
			if (app != null && app.has_key("Icon")) {
				icon = app.get_string("Icon");
			}
		}

		/**
		 * update_name will update the window name
		 */
		private void update_name() {
			if (window == null) {
				return;
			}

			string new_name = window.get_name();

			if (name != new_name) { // Actually changed
				name = new_name;
				name_changed(name);
			}
		}
	}
}
