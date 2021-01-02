/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017-2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace NightLight {
	[GtkTemplate (ui="/org/budgie-desktop/night-light/indicator_window.ui")]
	class IndicatorWindow : Budgie.Popover {
		[GtkChild]
		private Gtk.Switch? nightlight_switch;

		[GtkChild]
		private Gtk.Grid? item_grid;

		[GtkChild]
		private Gtk.SpinButton? temperature_spinbutton;

		[GtkChild]
		private Gtk.ComboBoxText? schedule_combobox;

		private Settings settings;

		public IndicatorWindow(Gtk.Widget? window_parent) {
			Object(relative_to: window_parent);

			settings = new Settings("org.gnome.settings-daemon.plugins.color");

			settings.bind("night-light-enabled", nightlight_switch, "active", SettingsBindFlags.DEFAULT);
			settings.bind("night-light-enabled", item_grid, "sensitive", SettingsBindFlags.DEFAULT);
			settings.bind("night-light-temperature", temperature_spinbutton, "value", SettingsBindFlags.DEFAULT);

			settings.changed["night-light-schedule-automatic"].connect(() => {
				schedule_combobox.set_active_id(settings.get_boolean("night-light-schedule-automatic").to_string());
			});

			schedule_combobox.set_active_id(settings.get_boolean("night-light-schedule-automatic").to_string());
		}

		public void toggle_nightlight() {
			bool enabled = settings.get_boolean("night-light-enabled");
			settings.set_boolean("night-light-enabled", !enabled);
		}

		[GtkCallback]
		private void schedule_mode_changed() {
			settings.set_boolean("night-light-schedule-automatic", bool.parse(schedule_combobox.get_active_id()));
		}

		[GtkCallback]
		private void open_settings() {
			DesktopAppInfo app_info = new DesktopAppInfo("gnome-display-panel.desktop");

			if (app_info == null) {
				return;
			}

			try {
				this.hide();
				app_info.launch(null, null);
			} catch (Error e) {
				message("Unable to launch gnome-display-panel.desktop: %s", e.message);
			}
		}
	}
}
