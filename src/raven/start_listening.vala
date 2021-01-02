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
	public class StartListening : Gtk.Box {
		private AppInfo? music_app = null; // Our current default music player that handles audio/ogg
		private bool has_music_player; // Private bool of whether or not we have a music player installed
		private Gtk.Button start_listening; // Our button to start listening to music

		public StartListening() {
			Object(orientation: Gtk.Orientation.VERTICAL, margin: 10);
			var label = new Gtk.Label("<big>%s</big>".printf(_("No apps are currently playing audio.")));
			label.justify = Gtk.Justification.CENTER;
			label.halign = Gtk.Align.CENTER;
			label.max_width_chars = 36;
			label.use_markup = true;
			label.valign = Gtk.Align.CENTER;
			label.wrap = true;
			label.wrap_mode = Pango.WrapMode.WORD;
			start_listening = new Gtk.Button.with_label(_("Play some music"));
			start_listening.hexpand = false;

			pack_start(label, true, true, 10);
			pack_start(start_listening, false, false, 0);

			var monitor = AppInfoMonitor.get(); // Get our AppInfoMonitor, which monitors the app info database for changes
			monitor.changed.connect(check_music_support); // Recheck music support

			start_listening.clicked.connect(launch_music_player);

			check_music_support(); // Do our initial check
		}

		/*
		* check_music_support will check if we have an application that supports vorbis.
		* We're checking for vorbis since it's more likely the end user has open source vorbis support than alternative codecs like MP3
		*/
		private void check_music_support() {
			music_app = AppInfo.get_default_for_type("audio/vorbis", false);
			has_music_player = (music_app != null);
			start_listening.set_visible(has_music_player); // Set the visibility of the button based on if we have a music player
		}

		private void launch_music_player() {
			if (music_app == null) {
				return;
			}

			try {
				music_app.launch(null, null);
			} catch (Error e) {
				warning("Unable to launch %s: %s", music_app.get_name(), e.message);
			}
		}
	}
}
