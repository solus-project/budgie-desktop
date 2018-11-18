/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2018 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {
    public class AppSoundControl : Gtk.Box {
        private Gvc.MixerControl? mixer = null;
        private Gvc.MixerStream? primary_stream = null;
        private Gvc.MixerStream? stream = null;
        private Gtk.Box? app_info_header = null;
        private Gtk.Image? app_image = null;
        private Gtk.Label? app_label = null;
        private Gtk.Button? app_mute_button = null;
        private Gtk.Scale? volume_slider = null;
        private bool muted = false;
        private uint32? volume;

        private Gtk.Image? audio_not_muted = null;
        private Gtk.Image? audio_muted = null;

        public string? app_name = "";
        private ulong scale_id;

        public AppSoundControl(Gvc.MixerControl c_mixer, Gvc.MixerStream c_primary, Gvc.MixerStream c_stream, string c_icon, string c_name) {
            Object(orientation: Gtk.Orientation.HORIZONTAL, margin: 10);
            valign = Gtk.Align.START;

            mixer = c_mixer;
            primary_stream = c_primary;
            stream = c_stream;
            app_name = c_name;

            var max_vol = stream.get_volume();
            var stream_volume = max_vol; // Create a non-manipulated copy
            var primary_stream_vol = primary_stream.get_base_volume();

            if (max_vol < primary_stream_vol) {
                max_vol = primary_stream_vol;
            }

            var max_vol_step = max_vol / 20;
            muted = (stream_volume <= max_vol_step); // Set our default muted state

            /**
             * App Desktop Logic
             * Firstly, check if the app name has a related desktop app info, and if so use the desktop name for the application.
             * Otherwise, use a titlized form of the app name if it'd match up with the description. Otherwise use app name.
             */
            bool successfully_retrieved_name = false;

            try {
                DesktopAppInfo info = new DesktopAppInfo(app_name + ".desktop"); // Attempt to get the application info

                if (info != null) {
                    string desktop_app_name = info.get_string("Name");

                    if ((desktop_app_name != "") && (desktop_app_name != null)) { // If we got the desktop app name
                        app_name = desktop_app_name;
                        successfully_retrieved_name = true;
                    }
                }
            } catch (Error e) {
                warning("Failed to get app info for this app: %s", e.message);
            }

            if (!successfully_retrieved_name) { // If we failed to get info from a desktop file
                string titled_app_name = app_name.substring(0,1).ascii_up() + app_name.substring(1);
                string description = stream.get_description();

                if (titled_app_name == description) {
                    app_name = description;
                }
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
            app_label.margin_left = 10;

            app_mute_button = new Gtk.Button();

            if (muted) { // If this app is already in a muted state
                if (stream.set_volume(0)) { // If we're technically at the threshold but may not be 0, set it to 0
                    Gvc.push_volume(stream);
                }
            }

            set_mute_ui();

            app_mute_button.get_style_context().add_class("flat");
            app_mute_button.clicked.connect(toggle_mute_state);

            app_info_header.pack_start(app_label, false, true, 0);
            app_info_header.pack_end(app_mute_button, false, false, 0);

            volume_slider = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 0, max_vol, max_vol_step);
            volume_slider.set_draw_value(false);
            volume_slider.set_increments(max_vol_step, max_vol_step);

            volume = stream_volume;
            volume_slider.set_value(stream_volume);

            scale_id = volume_slider.value_changed.connect(on_slider_change);

            app_info.pack_start(app_info_header, true, false, 0);
            app_info.pack_end(volume_slider, true, false, 0);

            /**
             * Icon logic
             */
            string stream_name = stream.get_name();

            try { // First let's try to get a reasonable app icon instead of whatever is provided by Gvc
                Gtk.IconTheme current_theme = Gtk.IconTheme.get_default(); // Get our default IconTheme
                string usable_icon_name = current_theme.has_icon(stream_name) ? stream_name : c_icon; // If our app has an icon, use it, otherwise use the stream icon name
                app_image = new Gtk.Image.from_icon_name(usable_icon_name, Gtk.IconSize.DND);
            } catch (Error e) { // If we failed to create a Gtk.Image with the app name
                warning("Failed to get an icon for this app. %s", e.message);
            }

            if (app_image != null) {
                app_image.margin_end = 10;
                pack_start(app_image, false, false, 0);
            }

            pack_end(app_info, true, true, 0);
        }

        /**
         * on_slider_change will handle when our volume_slider scale changes
         */
        public void on_slider_change() {
            var slider_value = volume_slider.get_value();

            SignalHandler.block(volume_slider, scale_id);
            uint32 stream_vol = (uint32) slider_value;

            volume = stream_vol;

            if (!muted) {
                if (stream.set_volume(stream_vol)) {
                    Gvc.push_volume(stream);
                }
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
        public void set_mute_ui() {
            if (muted) { // Muted
                app_mute_button.set_image(audio_muted);
            } else { // Not Muted
                app_mute_button.set_image(audio_not_muted);
            }
        }

        /**
         * toggle_mute_state will toggle the volume and internal muted state
         * This is done because gvc muted value change and tracking is fundamentally broken for apps
         */
        public void toggle_mute_state() {
            muted = !muted; // Invert muted state

            SignalHandler.block(volume_slider, scale_id);
            var local_vol = (muted) ? 0 : volume;

            if (stream.set_volume(local_vol)) {
                Gvc.push_volume(stream);
                set_mute_ui(); // Update our image
            }

            SignalHandler.unblock(volume_slider, scale_id);
        }
    }
}