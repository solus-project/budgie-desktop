/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

	// Long implementation note:
	// Caja is intentionally missing. While there is no doubt it is a fantastic file browser and well suited for the MATE Desktop, unfortunately Caja forces the drawing of the user background and as such it would make it cumbersome to support.
	// This support would require us to ensure whenever we update the background value in the GNOME schemas, we do the same for caja, and handle any added usecases where the schema doesn't exist.
	// Additionally, Caja's Desktop implementation sets itself to 0,0 and spans the entire XScreen, with no configuration for at least setting the beginning position / monitor for icons, or setting it not to span.
	public enum DesktopType {
		NONE = 0,
		BUDGIE = 1,
		DESKTOPFOLDER = 2,
		NEMO = 3
	}

	/**
	* DesktopPage allows users to change aspects of the fonts used
	*/
	public class DesktopPage : Budgie.SettingsPage {
		private Settings budgie_wm_settings;
		private Settings gnome_wm_settings;
		private Gtk.SpinButton? workspace_count;

		private Settings? budgie_desktop_view_settings;
		private Settings? desktop_folder_settings;
		private Settings? nemo_settings;

		private SettingsGrid? grid;
		private Gtk.Switch? show_switch;
		private Gtk.Switch? show_mounts;
		private Gtk.Switch? show_home;
		private Gtk.Switch? show_trash;
		private Gtk.ComboBox? icon_size;
		private Gtk.ComboBox? click_policy;

		// use_desktop_type indicates what type of desktop settings we should use. By default it is none, but allow it to be overridden if the system has multiple "solutions".
		// This also allows for the user to decide whether to go with the vendor's shipped solution or another.
		private int use_desktop_type = DesktopType.NONE;

		public DesktopPage() {
			Object(group: SETTINGS_GROUP_APPEARANCE,
				content_id: "desktop",
				title: _("Desktop"),
				display_weight: 1,
				icon_name: "preferences-desktop-wallpaper");

			budgie_wm_settings = new Settings("com.solus-project.budgie-wm");
			gnome_wm_settings = new Settings("org.gnome.desktop.wm.preferences"); // Set up our wm preferences Settings
			use_desktop_type = get_preferred_desktop_app(); // Either gets the desired type, native or none

			grid = new SettingsGrid();
			add(grid);

			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native implementation
				budgie_desktop_view_settings = new Settings("us.getsol.budgie-desktop-view"); // Get the settings for Budgie Desktop View
				budgie_desktop_view_settings.changed.connect(update_switches); // Update our switches on change
			} else if (use_desktop_type == DesktopType.DESKTOPFOLDER) { // Desktop Folder
				desktop_folder_settings = new Settings("com.github.spheras.desktopfolder"); // Get the settings for DesktopType
				desktop_folder_settings.changed.connect(update_switches); // Update our switches on change
			} else if (use_desktop_type == DesktopType.NEMO) { // Nemo
				nemo_settings = new Settings("org.nemo.desktop");
				nemo_settings.changed.connect(update_switches); // Update our switches on change
			}

			if (use_desktop_type != DesktopType.NONE) { // Using some desktop type, set up some universal options then implementation-specific
				show_switch = new Gtk.Switch(); // Universal show
				grid.add_row(new SettingsRow(show_switch,
					_("Desktop Icons"),
					_("Control whether to allow icons on the desktop.")
				));

				setup_show_binding();

				// DesktopFolder doesn't support fancy options like showing home folder, trash, or active mounts
				if (use_desktop_type != DesktopType.DESKTOPFOLDER) { // DesktopType is the only one that doesn't support showing mounts
					show_mounts = new Gtk.Switch(); // Switcher to show or hide active mounts
					grid.add_row(new SettingsRow(show_mounts,
						_("Active Mounts"),
						_("Show all active mounts on the desktop.")
					));

					setup_show_active_mounts_binding();

					show_home = new Gtk.Switch(); // Switcher to show or hide our Home folder
					grid.add_row(new SettingsRow(show_home,
						_("Home directory"),
						_("Add a shortcut to your home directory on the desktop.")
					));

					setup_show_home_binding();

					show_trash = new Gtk.Switch(); // Switcher to show or hide a shortcut to Trash
					grid.add_row(new SettingsRow(show_trash,
						_("Trash"),
						_("Add a shortcut to the Trash directory on the desktop.")
					));

					setup_show_trash_binding();
				}

				if (use_desktop_type == DesktopType.BUDGIE) { // DesktopType doesn't support icon size changing. Nemo might but needs validation.
					click_policy = new Gtk.ComboBox(); // Click Policy combo box
					setup_click_policy();

					icon_size = new Gtk.ComboBox(); // Icon Size combo box
					grid.add_row(new SettingsRow(icon_size,
						_("Icon Size"),
						_("Set the desired size of icons on the desktop.")
					));

					setup_icon_size();
				}
			}

			build_workspace_option(); // Immediately build our workspace option
			update_switches();
		}

		// build_workspace_option will build the workspace option for the settings
		private void build_workspace_option() {
			workspace_count = new Gtk.SpinButton.with_range(1, 8, 1); // Create our button, with a minimum of 1 workspace and max of 8
			workspace_count.set_value((double) gnome_wm_settings.get_int("num-workspaces")); // Set our default value

			workspace_count.value_changed.connect(() => { // On value change
				int new_val = workspace_count.get_value_as_int(); // Get the value as an int

				if (new_val < 1) { // Ensure valid minimum
					new_val = 1;
					workspace_count.set_value(1.0); // Set as 1
				} else if (new_val > 8) { // Ensure valid maximum
					new_val = 8;
					workspace_count.set_value(8.0); // Set as 8
				}

				gnome_wm_settings.set_int("num-workspaces", new_val); // Update num-workspaces
			});

			grid.add_row(new SettingsRow(workspace_count,
				_("Number of virtual desktops"),
				_("Number of virtual desktops / workspaces to create automatically on startup.")
			));
		}

		// get_exec_for_type will get the name of the executable for this type
		public string get_exec_for_type(int t) {
			switch (t) {
				case DesktopType.BUDGIE:
					return "us.getsol.budgie-desktop-view";
				case DesktopType.DESKTOPFOLDER:
					return "com.github.spheras.desktopfolder";
				case DesktopType.NEMO:
					return "nemo-desktop";
				default:
					return "none";
			}
		}

		// get_preferred_desktop_app will return the desired DesktopType
		public int get_preferred_desktop_app() {
			int desktop_override = budgie_wm_settings.get_enum("desktop-type-override"); // Get any override type

			if (
				(desktop_override != DesktopType.NONE) && // Preferred override
				(desktop_override != DesktopType.BUDGIE)
			) { // Which isn't the native implementation
					string desired_executable = get_exec_for_type(desktop_override); // Get the executable name of the desired desktop type

					if (Environment.find_program_in_path(desired_executable) != null) { // If we found the executable
						return desktop_override;
					}
			}

			// At this point we either don't have anything set or failed to get the executable for the desired type

			string budgie_path = get_exec_for_type(DesktopType.BUDGIE);

			if (Environment.find_program_in_path(budgie_path) != null) { // We at least have Budgie Desktop View
				return DesktopType.BUDGIE; // Always fall back to native when we can
			}

			return DesktopType.NONE; // At this point, claim we don't have anything
		}

		// is_showing will get the current show value from the respective desktop type
		private bool is_showing() {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				return budgie_desktop_view_settings.get_boolean("show");
			} else if (use_desktop_type == DesktopType.DESKTOPFOLDER) { // Desktop Folder
				return desktop_folder_settings.get_boolean("show-desktopfolder");
			} else if (use_desktop_type == DesktopType.NEMO) { // Nemo
				return nemo_settings.get_boolean("show-desktop-icons");
			}

			return false;
		}

		// setup_click_policy will set the up click_policy binding
		private void setup_click_policy()  {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				var render = new Gtk.CellRendererText();
				var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));

				Gtk.TreeIter iter;
				const string[] policies = { "single", "double" };

				foreach (var pol in policies) {
					model.append(out iter);
					string label_name = _("Single");

					if (pol == "double") {
						// If the click policy is to double click
						label_name = _("Double");
					}

					model.set(iter, 0, pol, 1, label_name, 2, pol, -1);
				}

				click_policy.set_model(model);
				click_policy.set_id_column(0);

				click_policy.pack_start(render, true);
				click_policy.add_attribute(render, "text", 1);

				budgie_desktop_view_settings.bind("click-policy", click_policy, "active-id", SettingsBindFlags.DEFAULT);

				grid.add_row(new SettingsRow(click_policy,
					_("Click Policy"),
					_("Click Policy determines if we should open items on a single or double click.")
				));
			}
		}

		// setup_show_binding will set up the show binding
		private void setup_show_binding() {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				budgie_desktop_view_settings.bind("show", show_switch, "active", SettingsBindFlags.DEFAULT);
			} else if (use_desktop_type == DesktopType.DESKTOPFOLDER) { // Desktop Folder
				desktop_folder_settings.bind("show-desktopfolder", show_switch, "active", SettingsBindFlags.DEFAULT);
			} else if (use_desktop_type == DesktopType.NEMO) { // Nemo
				nemo_settings.bind("show-desktop-icons", show_switch, "active", SettingsBindFlags.DEFAULT);
			}
		}

		// setup_show_active_mounts_binding will set up the show active mounts binding
		private void setup_show_active_mounts_binding() {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				budgie_desktop_view_settings.bind("show-active-mounts", show_mounts, "active", SettingsBindFlags.DEFAULT);
			} else if (use_desktop_type == DesktopType.NEMO) { // Nemo
				nemo_settings.bind("volumes-visible", show_mounts, "active", SettingsBindFlags.DEFAULT);
			}
		}

		// setup_show_home_binding will set up the show home folder binding
		private void setup_show_home_binding() {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				budgie_desktop_view_settings.bind("show-home-folder", show_home, "active", SettingsBindFlags.DEFAULT);
			} else if (use_desktop_type == DesktopType.NEMO) { // NEMO
				nemo_settings.bind("home-icon-visible", show_home, "active", SettingsBindFlags.DEFAULT);
			}
		}

		// setup_show_trash_binding will set up the show trash folder binding
		private void setup_show_trash_binding() {
			if (use_desktop_type == DesktopType.BUDGIE) { // Budgie native
				budgie_desktop_view_settings.bind("show-trash-folder", show_trash, "active", SettingsBindFlags.DEFAULT);
			} else if (use_desktop_type == DesktopType.NEMO) { // NEMO
				nemo_settings.bind("trash-icon-visible", show_trash, "active", SettingsBindFlags.DEFAULT);
			}
		}

		// setup_icon_size will set up the icon_size binding and model
		private void setup_icon_size() {
			var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));

			Gtk.TreeIter iter;
			const string[] icon_sizes = { "small", "normal", "large", "massive"};

			foreach (var s in icon_sizes) {
				model.append(out iter);
				string label_name = _("Normal");

				if (s == "small") { // Small
					label_name = _("Small");
				} else if (s == "large") { // Large
					label_name = _("Large");
				} else if (s == "massive") { // Massive
					label_name = _("Massive");
				}

				model.set(iter, 0, s, 1, label_name, 2, s, -1);
			}

			icon_size.set_model(model); // Set the icon size model
			icon_size.set_id_column(0);

			var render = new Gtk.CellRendererText();
			icon_size.pack_start(render, true);
			icon_size.add_attribute(render, "text", 1);

			budgie_desktop_view_settings.bind("icon-size", icon_size, "active-id", SettingsBindFlags.DEFAULT);
		}

		void update_switches() {
			if (use_desktop_type == DesktopType.NONE) { // No supported type
				return;
			}

			bool b = is_showing();

			if (show_mounts != null) {
				show_mounts.sensitive = b;
			}

			if (show_home != null) {
				show_home.sensitive = b;
			}

			if (show_trash != null) {
				show_trash.sensitive = b;
			}

			if (icon_size != null) {
				icon_size.sensitive = b;
			}
		}
	}
}
