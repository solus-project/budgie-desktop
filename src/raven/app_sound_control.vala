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
	public class AppSoundControl : Gtk.Box {
		private Gvc.MixerControl? mixer = null;
		public Gvc.MixerStream? primary_stream = null;
		public Gvc.MixerStream? stream = null;
		private Gtk.Box? app_info_header = null;
		private Gtk.Image? app_image = null;
		private Gtk.Label? app_label = null;
		private Gtk.Button? app_mute_button = null;
		private Gtk.Scale? volume_slider = null;
		private uint32? volume;

		private Gtk.Image? audio_not_muted = null;
		private Gtk.Image? audio_muted = null;

		public string? app_name = "";
		private ulong scale_id;

		public AppSoundControl(Gvc.MixerControl c_mixer, Gvc.MixerStream c_primary, Gvc.MixerStream c_stream, string c_icon, string c_name) {
			Object(orientation: Gtk.Orientation.HORIZONTAL, margin: 10);
			valign = Gtk.Align.START;

			if (c_mixer == null) {
				return;
			}

			if (c_primary == null) {
				return;
			}

			mixer = c_mixer;
			primary_stream = c_primary;
			stream = c_stream;
			app_name = c_name;

			/**
			 * App Desktop Logic
			 * Firstly, check if the app name has a related desktop app info, and if so use the desktop name for the application.
			 * Otherwise, use a titlized form of the app name if it'd match up with the description. Otherwise use app name.
			 */

			string alsa_beg = "ALSA plug-in [";
			if (app_name.has_prefix(alsa_beg)) {
				app_name = app_name.replace(alsa_beg, ""); // Remove the ALSA prefix
				app_name = app_name.substring(0, (app_name.length - 1)); // Replace the prefix
			}

			DesktopAppInfo info = new DesktopAppInfo(app_name + ".desktop"); // Attempt to get the application info

			if (info != null) { // Successfully got app info
				string desktop_app_name = info.get_string("Name");

				if ((desktop_app_name != "") && (desktop_app_name != null)) { // If we got the desktop app name
					app_name = desktop_app_name;
				}
			}

			string stream_name = stream.get_name();

			Gtk.IconTheme current_theme = Gtk.IconTheme.get_default(); // Get our default IconTheme
			string usable_icon_name = c_icon;

			if (current_theme.has_icon(app_name)) { // Has icon based on app name
				usable_icon_name = app_name;
			} else if (current_theme.has_icon(stream_name)) { // Has icon based on stream name
				usable_icon_name = stream_name; // Set to icon name
			}

			if (usable_icon_name != "applications-multimedia") { // Successfully got an icon from a valid app
				app_name = app_name.substring(0, 1).ascii_up() + app_name.substring(1); // Titalize the app name. Not doing this for non-compliant icons means apps like mocp don't get wrongly titalized.
			}

			/**
			 * Create initial elements
			 */
			audio_not_muted = new Gtk.Image.from_icon_name("audio-volume-high-symbolic", Gtk.IconSize.MENU);
			audio_muted = new Gtk.Image.from_icon_name("audio-volume-muted-symbolic", Gtk.IconSize.MENU);

			Gtk.Box app_info = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			app_info_header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

			app_label = new Gtk.Label(app_name); // Create a new label with the app name
			app_label.ellipsize = Pango.EllipsizeMode.END;
			app_label.halign = Gtk.Align.START; // Align to edge (left for LTR; right for RTL)
			app_label.justify = Gtk.Justification.LEFT;
			app_label.margin_start = 10;

			app_mute_button = new Gtk.Button();

			set_mute_ui();

			app_mute_button.get_style_context().add_class("flat");
			app_mute_button.clicked.connect(toggle_mute_state);

			app_info_header.pack_start(app_label, false, true, 0);
			app_info_header.pack_end(app_mute_button, false, false, 0);

			var max_vol = this.get_base_volume();
			var stream_volume = stream.get_volume();
			var max_vol_step = max_vol / 20; // Default to steps of 20

			volume_slider = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, max_vol, max_vol_step);
			volume_slider.set_draw_value(false);
			volume_slider.set_increments(max_vol_step, max_vol_step);

			volume = stream_volume;
			volume_slider.set_value(stream_volume);

			scale_id = volume_slider.value_changed.connect(on_slider_change);

			app_info.pack_start(app_info_header, true, false, 0);
			app_info.pack_end(volume_slider, true, false, 0);

			app_image = new Gtk.Image.from_icon_name(usable_icon_name, Gtk.IconSize.DND);

			if (app_image != null) {
				app_image.margin_end = 10;
				pack_start(app_image, false, false, 0);
			}

			pack_end(app_info, true, true, 0);
		}

		/**
		 * get_base_volume will get the recommended base volume based on the stream and primary device stream
		 */
		private uint32 get_base_volume() {
			var base_vol = stream.get_volume();
			var primary_stream_vol = primary_stream.get_base_volume();
			return (base_vol < primary_stream_vol) ? primary_stream_vol : base_vol;
		}

		/**
		 * on_slider_change will handle when our volume_slider scale changes
		 */
		private void on_slider_change() {
			var slider_value = volume_slider.get_value();

			SignalHandler.block(volume_slider, scale_id);
			uint32 stream_vol = (uint32) slider_value;

			volume = stream_vol;

			if (stream.set_volume(stream_vol)) {
				Gvc.push_volume(stream);
			}

			SignalHandler.unblock(volume_slider, scale_id);
		}

		/**
		 * refresh is responsible for performing UI refresh / updating
		 */
		public void refresh() {
			var stream_name = stream.get_name();

			if (app_name != stream_name) { // If the application name has changed
				app_name = stream_name;
				app_label.label = stream_name;
			}

			refresh_volume(); // Refresh the volume
		}

		/**
		 * refresh_volume is our function for updating the volume slider and mute UI
		 */
		public void refresh_volume() {
			var vol = stream.get_volume();

			if (volume_slider.get_value() != vol) { // If the volume has changed
				volume_slider.set_value(vol); // Update volume slider value
			}

			volume = vol;
			set_mute_ui(); // Ensure we have an updated mute
		}

		/**
		 * set_mute_ui will set the image for the app_mute_button and change dim state of the input
		 */
		private void set_mute_ui() {
			if (stream.get_is_muted()) {
				app_mute_button.set_image(audio_muted);
			} else {
				app_mute_button.set_image(audio_not_muted);
			}
		}

		private void toggle_mute_state() {
			SignalHandler.block(volume_slider, scale_id);
			stream.change_is_muted(!stream.get_is_muted());
			stream.set_is_muted(!stream.get_is_muted());
			set_mute_ui();
			SignalHandler.unblock(volume_slider, scale_id);
		}
	}
}
