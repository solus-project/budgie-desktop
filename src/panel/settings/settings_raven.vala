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
	/**
	* RavenPage shows options for configuring Raven
	*/
	public class RavenPage : Budgie.SettingsPage {
		private Gtk.ComboBox? raven_position;
		private Gtk.Switch? allow_volume_overdrive;
		private Gtk.Switch? enable_week_numbers;
		private Gtk.Switch? show_calendar_widget;
		private Gtk.Switch? show_sound_output_widget;
		private Gtk.Switch? show_mic_input_widget;
		private Gtk.Switch? show_mpris_widget;
		private Gtk.Switch? show_powerstrip;
		private Settings raven_settings;

		public RavenPage() {
			Object(group: SETTINGS_GROUP_APPEARANCE,
				content_id: "raven",
				title: "Raven",
				display_weight: 3,
				icon_name: "preferences-calendar-and-tasks" // Subject to change
			);

			var grid = new SettingsGrid();
			this.add(grid);

			raven_position = new Gtk.ComboBox();

			// Add options for Raven position
			var render = new Gtk.CellRendererText();
			var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(RavenPosition));
			Gtk.TreeIter iter;
			const RavenPosition[] positions = {
				RavenPosition.AUTOMATIC,
				RavenPosition.LEFT,
				RavenPosition.RIGHT
			};

			foreach (var pos in positions) {
				model.append(out iter);
				model.set(iter, 0, pos.to_string(), 1, pos.get_display_name(), 2, pos, -1);
			}

			raven_position.set_model(model);
			raven_position.pack_start(render, true);
			raven_position.add_attribute(render, "text", 1);
			raven_position.set_id_column(0);

			grid.add_row(new SettingsRow(raven_position,
				_("Set Raven position"),
				_("Set which side of the screen Raven will open on. If set to Automatic, Raven will open where its parent panel is.")
			));

			allow_volume_overdrive = new Gtk.Switch();
			grid.add_row(new SettingsRow(allow_volume_overdrive,
				_("Allow raising volume above 100%"),
				_("Allows raising the volume via Sound Settings as well as the Sound Output Widget in Raven up to 150%.")
			));
			enable_week_numbers = new Gtk.Switch();
			grid.add_row(new SettingsRow(enable_week_numbers,
				_("Enable display of week numbers in Calendar"),
				_("This setting enables the display of week numbers in the Calendar widget.")
			));

			show_calendar_widget = new Gtk.Switch();
			grid.add_row(new SettingsRow(show_calendar_widget,
				_("Show Calendar Widget"),
				_("Shows or hides the Calendar Widget in Raven's Applets section.")
			));

			show_sound_output_widget = new Gtk.Switch();
			grid.add_row(new SettingsRow(show_sound_output_widget,
				_("Show Sound Output Widget"),
				_("Shows or hides the Sound Output Widget in Raven's Applets section.")
			));

			show_mic_input_widget = new Gtk.Switch();
			grid.add_row(new SettingsRow(show_mic_input_widget,
				_("Show Microphone Input Widget"),
				_("Shows or hides the Microphone Input Widget in Raven's Applets section.")
			));

			show_mpris_widget = new Gtk.Switch();
			grid.add_row(new SettingsRow(show_mpris_widget,
				_("Show Media Playback Controls Widget"),
				_("Shows or hides the Media Playback Controls (MPRIS) Widget in Raven's Applets section.")
			));

			show_powerstrip = new Gtk.Switch();
			grid.add_row(new SettingsRow(show_powerstrip,
				_("Show Power Strip"),
				_("Shows or hides the Power Strip in the bottom of Raven.")
			));

			raven_settings = new Settings("com.solus-project.budgie-raven");
			raven_settings.bind("raven-position", raven_position, "active-id", SettingsBindFlags.DEFAULT);
			raven_settings.bind("allow-volume-overdrive", allow_volume_overdrive, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("enable-week-numbers", enable_week_numbers, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("show-calendar-widget", show_calendar_widget, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("show-sound-output-widget", show_sound_output_widget, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("show-mic-input-widget", show_mic_input_widget, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("show-mpris-widget", show_mpris_widget, "active", SettingsBindFlags.DEFAULT);
			raven_settings.bind("show-power-strip", show_powerstrip, "active", SettingsBindFlags.DEFAULT);
		}
	}
}
