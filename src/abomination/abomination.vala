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

private const string RAVEN_DBUS_NAME = "org.budgie_desktop.Raven";
private const string RAVEN_DBUS_OBJECT_PATH = "/org/budgie_desktop/Raven";

[DBus (name="org.budgie_desktop.Raven")]
public interface AbominationRavenRemote : GLib.Object {
	public async abstract void SetPauseNotifications(bool paused) throws DBusError, IOError;
}

namespace Budgie {
	/**
	 * Abomination is our application state tracking manager
	 */
	public class Abomination : GLib.Object {
		private Budgie.AppSystem? app_system = null;
		private Settings? color_settings = null;
		private Settings? wm_settings = null;
		private bool original_night_light_setting = false;
		private bool should_disable_night_light_on_fullscreen = false;
		private bool should_pause_notifications_on_fullscreen = false;

		public HashTable<ulong?,Wnck.Window?> fullscreen_windows; // fullscreen_windows is a list of fullscreen windows based on their X window ID and respective Wnck.Window
		// FIXME: Deprecate with running_app_groups
		public HashTable<string?,Array<AbominationRunningApp>?> running_apps; // running_apps is a list of running apps based on the group name and AbominationRunningApp
		public HashTable<ulong?,AbominationRunningApp?> running_apps_id; // running_apps_ids is a list of apps based on the window id and AbominationRunningApp
		public HashTable<string?,AbominationAppGroup?> running_app_groups; // running_app_groups is a list of app groups based on the group name

		private Wnck.Screen screen = null;
		private AbominationRavenRemote? raven_proxy = null;

		private ulong color_id = 0;

		/**
		 * Signals
		 */
		public signal void added_app(string group, AbominationRunningApp app);
		public signal void removed_app(string group, AbominationRunningApp app);
		public signal void update_group(AbominationAppGroup group);

		public Abomination() {
			this.app_system = new Budgie.AppSystem();
			this.color_settings = new Settings("org.gnome.settings-daemon.plugins.color");
			this.wm_settings = new Settings("com.solus-project.budgie-wm");

			this.fullscreen_windows = new HashTable<ulong?,Wnck.Window?>(int_hash, str_equal);
			this.running_apps = new HashTable<string?,Array<AbominationRunningApp>?>(str_hash, str_equal);
			this.running_apps_id = new HashTable<ulong?,AbominationRunningApp?>(int_hash, int_equal);
			this.running_app_groups = new HashTable<string?,AbominationAppGroup?>(str_hash, str_equal);

			this.screen = Wnck.Screen.get_default();

			Bus.get_proxy.begin<AbominationRavenRemote>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);

			if (this.color_settings != null) { // gsd colors plugin schema defined
				this.update_night_light_value();
				this.color_id = color_settings.changed["night-light-enabled"].connect(update_night_light_value);
			}

			if (this.wm_settings != null) {
				this.update_should_disable_night_light();
				this.update_should_pause_notifications();

				this.wm_settings.changed["disable-night-light-on-fullscreen"].connect(update_should_disable_night_light);
				this.wm_settings.changed["pause-notifications-on-fullscreen"].connect(update_should_pause_notifications);
			}

			this.screen.window_opened.connect(this.add_app);
			this.screen.window_closed.connect(this.remove_app);

			screen.get_windows().foreach((window) => { // Init all our current running windows
				add_app(window);
			});
		}

		/* Hold onto our Raven proxy ref */
		void on_raven_get(Object? o, AsyncResult? res) {
			try {
				raven_proxy = Bus.get_proxy.end(res);
			} catch (Error e) {
				warning("Failed to gain Raven proxy: %s", e.message);
			}
		}

		/**
		 * is_disallowed_window_type will check if this specified window is a disallowed type
		 */
		public bool is_disallowed_window_type(Wnck.Window window) {
			Wnck.WindowType win_type = window.get_window_type(); // Get the window type

			return (win_type == Wnck.WindowType.DESKTOP) || // Desktop-mode (like Nautilus' Desktop Icons)
				   (win_type == Wnck.WindowType.DIALOG) || // Dialogs
				   (win_type == Wnck.WindowType.DOCK) || // Like Budgie Panel
				   (win_type == Wnck.WindowType.SPLASHSCREEN) || // Splash screens
				   (win_type == Wnck.WindowType.UTILITY); // Utility like a control on an emulator
		}

		/**
		 * Get the first running app of an app group identified by its name.
		 */
		public AbominationRunningApp? get_first_app_of_group(string group) {
			Array<Budgie.AbominationRunningApp> group_apps = this.running_apps.get(group);
			if (group_apps == null) {
				return null;
			}

			Budgie.AbominationRunningApp first_app = group_apps.index(0);
			if (first_app == null) {
				return null;
			}

			if ((first_app.window != null) && (first_app.window.get_state() == Wnck.WindowState.SKIP_TASKLIST)) {
				return null;
			}

			return first_app;
		}

		public AbominationAppGroup? get_window_group(Wnck.Window window) {
			string group_name = this.get_group_name(window);
			if (!this.running_app_groups.contains(group_name)) {
				return null;
			}
			return this.running_app_groups.get(group_name);
		}

		/**
		 * add_app will add a running application based on the provided window
		 */
		private void add_app(Wnck.Window window) {
			// Could use group name to determine if apps can be grouped together
			//  warning("Opened in Group: %s (App Name: %s / %s)", window.get_class_group_name(), window.get_name(), window.get_class_instance_name());
			// So far, here are the apps without a groupname:
			//  - Android studio emulator (null)
			//  - GTK4 demos (empty string) -> how to make it so that grouping works? (only application class cuz it's another windows with controls)
			//  - LibreOffice (first open null, then open the app, but icon isn't here)
			//  - Chrome with multi profiles (get_class_instance_name is still null...) will have to do an hard check on this one cuz it's impossible otherwise...

			// LibreOffice have different behavior depending on how it was started
			// Test grouping of chrome canary / dev / snap / flatpak too (works)

			if (this.is_disallowed_window_type(window)) { // Disallowed type
				return;
			}

			if (window.is_skip_pager() || window.is_skip_tasklist()) { // Skip pager or tasklist
				return;
			}

			AbominationAppGroup group = this.get_window_group(window);
			if (group == null) {
				group = new AbominationAppGroup(window);
				this.running_app_groups.insert(group.get_name(), group);
			}

			group.add_window(window);

			AbominationRunningApp app = new AbominationRunningApp(this.app_system, window, group); // Create an abomination app
			if (app == null || app.group == null) { // Shouldn't be the case, fail immediately
				return;
			}

			Array<AbominationRunningApp>? group_apps = this.running_apps.get(app.group);
			if (group_apps == null) { // Not defined group apps
				group_apps = new Array<AbominationRunningApp>();
				this.running_apps.insert(app.group, group_apps);
			}

			group_apps.append_val(app); // Append the app

			this.running_apps_id.insert(app.id, app); // Append the app based on id
			this.added_app(app.group, app); // notify that the app was added

			this.track_window_fullscreen_state(app.window, app.window.get_state());

			app.class_changed.connect((old_class_name, new_class) => {
				this.rename_group(old_class_name, new_class); // Rename the class
			});

			app.window.state_changed.connect((changed, new_state) => {
				if (Wnck.WindowState.FULLSCREEN in (changed | new_state)) {
					this.track_window_fullscreen_state(app.window, new_state);
				}
			});

			// FIXME: GTK4 demo, try opening multiple instances as well as multiples instances of Application class, number of window shown is incorrect
			// FIXME: Android studio, cannot switch between windows (only after having closed an reopened the second window), same for VirtualBox VMs (basically same for all the non-pinned apps)
		}

		/**
		 * remove_app will remove a running application based on the provided window
		 *
		 * FIXME: sometime closing one instance of a grouped app will remove all..
		 */
		private void remove_app(Wnck.Window window) {
			AbominationAppGroup group = this.get_window_group(window);
			if (group == null) { // shouldn't happen
				return;
			}

			group.remove_window(window);

			if (group.get_windows().length() == 0) { // remove empty group
				this.running_app_groups.remove(group.get_name());
				warning("Removed group: %s", group.get_name());
			}

			ulong id = window.get_xid();
			AbominationRunningApp app = this.running_apps_id.get(id); // Get the running app

			this.running_apps_id.steal(id); // Remove from running_apps_id

			this.track_window_fullscreen_state(window, null); // Remove from fullscreen_windows and toggle state if necessary

			if (app != null) { // App is defined
				Array<AbominationRunningApp> group_apps = this.running_apps.get(app.group); // Get apps based on group name

				if (group_apps != null) { // Failed to get the app based on group
					for (int i = 0; i < group_apps.length; i++) {
						AbominationRunningApp item = group_apps.index(i);

						if (item.id == app.id) { // Matches
							group_apps.remove_index(i);
							break;
						}
					}
				}

				this.removed_app(app.group, app); // Notify that we called remove

				if (group_apps != null) {
					if (group_apps.length == 0) {
						this.running_apps.steal(app.group); // Dropkick from running apps
					}
				} else {
					this.running_apps.steal(app.group); // Dropkick from running apps
				}
			}
		}

		/**
		 * rename_group will rename any associated group based on the old group name
		 * The old group name is determined by current windows associated with the group
		 */
		private void rename_group(string old_group_name, AbominationAppGroup group) {
			List<weak Wnck.Window> windows = group.get_windows();
			if (windows.length() == 0) {
				return;
			}

			// FIXME: Apps are in the same group, yet they are not grouped together - why? (only apply to libre-office)
			// Because soffice, then libre-office...

			string new_group_name = this.get_group_name(windows.nth_data(0));
			AbominationAppGroup new_group = new AbominationAppGroup(windows.nth_data(0));
			foreach (var window in group.get_windows()) { // add existing windows to new group
				new_group.add_window(window);

				AbominationRunningApp app = this.running_apps_id.get(window.get_xid());
				if (app == null) { // shouldn't happen if we do our job correctly, yet better safe than sorry
					continue;
				}

				app.group = new_group_name;
				app.group_object = new_group;
			}

			this.running_app_groups.insert(new_group_name, new_group); // add the new group
			this.running_app_groups.remove(group.get_name()); // remove old group

			// FIXME: probably this.running_apps doesn't contains all the windows...
			// FIXME: libre office is doing shit with the popover, etc, what a shitty app
			Array<AbominationRunningApp> apps_associated_with_old_group = this.running_apps.get(old_group_name);

			this.running_apps.steal(old_group_name); // Remove for "rename"
			this.running_apps.insert(new_group_name, apps_associated_with_old_group); // Re-add for "rename"

			this.update_group(new_group); // Should always be invoked last
		}

		/**
		 * Adds and removes windows from fullscreen_windows depending on their state.
		 * Additionally, toggles night light and notification pausing as necessary if either are enabled.
		 */
		private void track_window_fullscreen_state(Wnck.Window window, Wnck.WindowState? state) {
			ulong window_xid = window.get_xid();

			// only add a fullscreen window if it isn't currently minimized
			if (!(window_xid in fullscreen_windows) && state_is_fullscreen(state)) {
				fullscreen_windows.insert(window_xid, window); // Add to fullscreen_windows
			} else if (window_xid in fullscreen_windows) {
				fullscreen_windows.steal(window_xid); // Remove from fullscreen_windows
			}

			toggle_night_light(); // Ensure we toggle Night Light if needed
			set_notifications_paused(); // Ensure we pause notifications if needed
		}

		private bool state_is_fullscreen(Wnck.WindowState? state) {
			return state != null && (
				Wnck.WindowState.FULLSCREEN in state &&
				!(Wnck.WindowState.MINIMIZED in state || Wnck.WindowState.HIDDEN in state)
			);
		}

		/**
		 * toggle_night_light will toggle the state of the night light depending on requested state
		 * If we're disabling, we'll check if there is any items in fullscreen_windows first
		 */
		private void toggle_night_light() {
			if (should_disable_night_light_on_fullscreen) {
				SignalHandler.block(color_settings, color_id);

				if (fullscreen_windows.size() >= 1) { // Has fullscreen windows
					color_settings.set_boolean("night-light-enabled", false);
				} else { // Has no fullscreen windows
					color_settings.set_boolean("night-light-enabled", original_night_light_setting); // Set back to our original
				}

				SignalHandler.unblock(color_settings, color_id);
			}
		}

		private void set_notifications_paused() {
			if (should_pause_notifications_on_fullscreen) {
				raven_proxy.SetPauseNotifications.begin(fullscreen_windows.size() >= 1);
			}
		}

		/**
		 * update_should_disable_night_light will update our value determining if we should disable night light on fullscreen
		 */
		private void update_should_disable_night_light() {
			if (wm_settings != null) {
				should_disable_night_light_on_fullscreen = wm_settings.get_boolean("disable-night-light-on-fullscreen");
			}
		}

		/**
		 * update_should_pause_notifications will update our value determining if we should pause notifications on fullscreen
		 */
		private void update_should_pause_notifications() {
			if (wm_settings != null) {
				should_pause_notifications_on_fullscreen = wm_settings.get_boolean("pause-notifications-on-fullscreen");
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

		private string get_group_name(Wnck.Window window) {
			// Try to use class group name from WM_CLASS as it's the most precise.
			string name = window.get_class_group_name();

			// Fallback to using class instance name (still from WM_CLASS),
			// less precise, if app is part of a "family", like libreoffice,
			// instance will always be libreoffice.
			if (name == null) {
				name = window.get_class_instance_name();
			}

			// Fallback to using name (when WM_CLASS isn't set).
			// i.e. Chrome profile launcher, android studio emulator
			if (name == null) {
				name = window.get_name();
			}

			if (name != null) {
				name = name.down();
			}

			// Chrome profile launcher doesn't have WM_CLASS, so name is used
			// instead and is not the same as the group of the window opened afterward.
			if (name == "google chrome") {
				name = "google-chrome";
			}

			return name;
		}
	}

	public class AbominationRunningApp : GLib.Object {
		public DesktopAppInfo? app = null;
		public string group; // Group assigned to the app
		public AbominationAppGroup group_object; // Actual AbominationAppGroup object
		public string icon; // Icon associated with this app
		public string name; // App name
		public ulong id; // Window id
		public Wnck.Window window; // Window of app

		private Budgie.AppSystem? app_system = null;

		/**
		 * Signals
		 */
		public signal void class_changed(string old_class_name, AbominationAppGroup class);
		public signal void icon_changed(string icon_name);
		public signal void name_changed(string name);

		public AbominationRunningApp(Budgie.AppSystem app_system, Wnck.Window window, AbominationAppGroup group) {
			set_window(window);

			if (this.window != null) {
				this.id = this.window.get_xid();
				this.name = this.window.get_name();
				this.group_object = group;
			}

			this.app_system = app_system;

			update_group();
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
					set_window(this.window); // Set our bindings
				} else if (!found_new_window && this.app != null) { // If we didn't find the new window but we at least have the DesktopAppInfo
					this.name = this.app.get_display_name(); // Just fallback to the DesktopAppInfo display name
				}
			}
		}

		/**
		 * set_window will handle setting our window and its bindings
		 */
		private void set_window(Wnck.Window window) {
			if (window == null) { // Window provided is null
				return;
			}

			this.window = window;
			update_icon();
			update_name();

			this.window.class_changed.connect(() => {
				string old_group = this.group;

				update_group();
				update_icon();
				update_name();

				if (this.group != old_group) { // Actually changed
					if (this.group.has_prefix("chrome-")) {
						return;
					}

					class_changed(old_group, this.group_object); // Signal that the class changed
				}
			});

			this.window.icon_changed.connect(() => {
				string old_icon = this.icon;
				update_icon();

				if (this.icon != old_icon) { // Actually changed
					icon_changed(this.icon);
				}
			});

			this.window.name_changed.connect(() => {
				update_name();
			});

			this.window.state_changed.connect(() => {
				update_name();
			});
		}

		/**
		 * update_group will update our group
		 */
		private void update_group() {
			if (this.window == null) { // Window no longer valid
				return;
			}

			this.app = this.app_system.query_window(this.window);
			// FIXME: dedup the logic
			this.group = this.window.get_class_instance_name();

			if (this.group == null) { // Fallback to using class group name
				this.group = this.window.get_class_group_name();
			}

			if (this.group == null) { // Fallback to using name
				this.group = this.name;
			}

			if (this.group != null) {
				this.group = this.group.down();
			}

			if (this.group == "google chrome") { // google chrome profile launcher doesn't have WM_CLASS, so its name is used instead
				this.group = "google-chrome";
			}

			//  warning("App group: %s", this.group);
			//  warning("Number of window: %u", this.group_object.get_windows().length());
		}

		/**
		 * update_icon will update our icon
		 */
		private void update_icon() {
			if (this.app != null && this.app.has_key("Icon")) { // Got app info
				this.icon = this.app.get_string("Icon");
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
					name_changed(this.name);
				}
			}
		}
	}

	/**
	 * A replacement for Wnck.ClassGroup as Wnck.ClassGroup relies on the sometime
	 * missing, sometime incoherent WM_CLASS property to group windows together.
	 */
	public class AbominationAppGroup : GLib.Object {
		private string name;
		private HashTable<ulong?,Wnck.Window?> windows;

		/**
		 * Signals
		 */
		public signal void icon_changed();
		public signal void added_window(Wnck.Window window);
		public signal void removed_window(Wnck.Window window);

		/**
		 * Create a new group from a window instance
		 */
		public AbominationAppGroup(Wnck.Window window) {
			this.windows = new HashTable<ulong?,Wnck.Window?>(int_hash, int_equal);

			// Try to use class group name from WM_CLASS as it's the most precise.
			string name = window.get_class_group_name();

			// Fallback to using class instance name (still from WM_CLASS),
			// less precise, if app is part of a "family", like libreoffice,
			// instance will always be libreoffice.
			if (name == null) {
				name = window.get_class_instance_name();
			}

			// Fallback to using name (when WM_CLASS isn't set).
			// i.e. Chrome profile launcher, android studio emulator
			if (name == null) {
				name = window.get_name();
			}

			name = name.down();

			// Chrome profile launcher doesn't have WM_CLASS, so name is used
			// instead and is not the same as the group of the window opened afterward.
			if (name == "google chrome") {
				name = "google-chrome";
			}

			this.name = name;

			warning("Created group: %s", this.name);

			// FIXME: error: Signal `Budgie.AbominationAppGroup.icon_changed' requires emitter in this context
			//  window.icon_changed.connect(this.icon_changed); // pass signal to whoever is listening
		}

		public void add_window(Wnck.Window window) {
			if (this.windows.contains(window.get_xid())) {
				return;
			}

			this.windows.insert(window.get_xid(), window);

			warning("Number of window: %u (group: %s)", this.get_windows().length(), this.name);

			this.added_window(window);
		}

		public void remove_window(Wnck.Window window) {
			if (!this.windows.contains(window.get_xid())) {
				return;
			}

			this.windows.remove(window.get_xid());

			warning("Number of window: %u (group: %s)", this.get_windows().length(), this.name);

			this.removed_window(window);
		}

		public List<weak Wnck.Window> get_windows() {
			return this.windows.get_values();
		}

		public string get_name() {
			return this.name;
		}

		public Gdk.Pixbuf? get_icon() {
			// FIXME: should probably be the window that has WM_CLASS defined
			return this.get_windows().nth_data(0).get_class_group().get_icon();
		}
	}
}
