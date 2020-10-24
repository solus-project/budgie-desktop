/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
	/**
	* DesktopPage allows users to change aspects of the fonts used
	*/
	public class DesktopPage : Budgie.SettingsPage {
		private Settings wm_pref_settings;
		private Gtk.SpinButton? workspace_count;

#if HAVE_BUDGIE_DESKTOP_VIEW
		private Settings view_settings;
		private Gtk.Switch? show_switch;
		private Gtk.Switch? show_mounts;
		private Gtk.Switch? show_home;
		private Gtk.Switch? show_trash;
		private Gtk.ComboBox? icon_size;
#endif

		public DesktopPage() {
			Object(group: SETTINGS_GROUP_APPEARANCE,
				content_id: "desktop",
				title: _("Desktop"),
				display_weight: 1,
				icon_name: "preferences-desktop-wallpaper");

			var grid = new SettingsGrid();
			this.add(grid);

#if HAVE_BUDGIE_DESKTOP_VIEW
			show_switch = new Gtk.Switch(); // Switcher to show or hide desktop icons
			grid.add_row(new SettingsRow(show_switch,
				_("Desktop Icons"),
				_("Control whether to allow icons on the desktop.")
			));

			show_mounts = new Gtk.Switch(); // Switcher to show or hide active mounts
			grid.add_row(new SettingsRow(show_mounts,
				_("Active Mounts"),
				_("Show all active mounts on the desktop.")
			));

			show_home = new Gtk.Switch(); // Switcher to show or hide our Home folder
			grid.add_row(new SettingsRow(show_home,
				_("Home directory"),
				_("Add a shortcut to your home directory on the desktop.")
			));

			show_trash = new Gtk.Switch(); // Switcher to show or hide a shortcut to Trash
			grid.add_row(new SettingsRow(show_trash,
				_("Trash"),
				_("Add a shortcut to the Trash directory on the desktop.")
			));

			icon_size = new Gtk.ComboBox(); // Icon Size combo box
			grid.add_row(new SettingsRow(icon_size,
				_("Icon Size"),
				_("Set the desired size of icons on the desktop.")
			));

			view_settings = new Settings("us.getsol.budgie-desktop-view"); // Get our budgie-desktop-view settings

			//var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Budgie.DesktopItemSize));
			var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(string));

			Gtk.TreeIter iter;
			const string[] z = { "small", "normal", "large", "massive"};

			foreach (var s in z) {
				model.append(out iter);
				model.set(iter, 0, s, 1, icon_size_to_label(s), 2, s, -1);
			}

			icon_size.set_model(model); // Set the icon size model
			icon_size.set_id_column(0);

			var render = new Gtk.CellRendererText();
			icon_size.pack_start(render, true);
			icon_size.add_attribute(render, "text", 1);
			//icon_size.set_active(view_settings.get_enum("icon-size"));

			view_settings.bind("show", show_switch, "active", SettingsBindFlags.DEFAULT);
			view_settings.bind("show-active-mounts", show_mounts, "active", SettingsBindFlags.DEFAULT);
			view_settings.bind("show-home-folder", show_home, "active", SettingsBindFlags.DEFAULT);
			view_settings.bind("show-trash-folder", show_trash, "active", SettingsBindFlags.DEFAULT);
			view_settings.bind("icon-size", icon_size, "active-id", SettingsBindFlags.DEFAULT);

			update_switches();
			view_settings.changed.connect(update_switches); // Update our switches when settings get changed. useful for dynamic sensitive changing
#endif

			wm_pref_settings = new Settings("org.gnome.desktop.wm.preferences"); // Set up our wm preferences Settings

			workspace_count = new Gtk.SpinButton.with_range(1, 8, 1); // Create our button, with a minimum of 1 workspace and max of 8
			workspace_count.set_value((double) wm_pref_settings.get_int("num-workspaces")); // Set our default value

			workspace_count.value_changed.connect(() => { // On value change
				int new_val = workspace_count.get_value_as_int(); // Get the value as an int

				if (new_val < 1) { // Ensure valid minimum
					new_val = 1;
					workspace_count.set_value(1.0); // Set as 1
				} else if (new_val > 8) { // Ensure valid maximum
					new_val = 8;
					workspace_count.set_value(8.0); // Set as 8
				}

				wm_pref_settings.set_int("num-workspaces", new_val); // Update num-workspaces
			});

			grid.add_row(new SettingsRow(workspace_count,
				_("Number of virtual desktops"),
				_("Number of virtual desktops / workspaces to create automatically on startup.")
			));
		}

#if HAVE_BUDGIE_DESKTOP_VIEW
		// Get the text for each desktop icon size
		public string icon_size_to_label(string size) {
			switch (size) {
				case "small":
					return _("Small");
				case "large":
					return _("Large");
				case "massive":
					return _("Massive");
				default:
					return _("Normal");
			}
		}

		void update_switches() {
			bool b = view_settings.get_boolean("show");
			show_mounts.sensitive = b;
			show_home.sensitive = b;
			show_trash.sensitive = b;
			icon_size.sensitive = b;
		}
#endif
	}
}
