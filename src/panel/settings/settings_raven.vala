/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
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
