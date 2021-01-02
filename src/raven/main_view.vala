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
	public class MainView : Gtk.Box {
		private Gtk.Box? box = null; // Holds our content
		private MprisWidget? mpris = null;
		private CalendarWidget? cal = null;
		private Budgie.SoundWidget? audio_input_widget = null;
		private Budgie.SoundWidget? audio_output_widget = null;
		private Settings? raven_settings = null;

		private Gtk.Stack? main_stack = null;
		private Gtk.StackSwitcher? switcher = null;
		private string SHOW_SOUND_OUTPUT_WIDGET = "show-sound-output-widget";
		private string SHOW_MIC_INPUT_WIDGET = "show-mic-input-widget";

		public signal void requested_draw(); // Request the window to redraw itself

		public void expose_notification() {
			main_stack.set_visible_child_name("notifications");
		}

		public MainView() {
			Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
			raven_settings = new Settings("com.solus-project.budgie-raven");
			raven_settings.changed.connect(this.on_raven_settings_changed);

			var header = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			header.get_style_context().add_class("raven-header");
			header.get_style_context().add_class("top");
			main_stack = new Gtk.Stack();
			pack_start(header, false, false, 0);

			/* Anim */
			main_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
			switcher = new Gtk.StackSwitcher();

			switcher.valign = Gtk.Align.CENTER;
			switcher.margin_top = 4;
			switcher.margin_bottom = 4;
			switcher.set_halign(Gtk.Align.CENTER);
			switcher.set_stack(main_stack);
			header.pack_start(switcher, true, true, 0);

			pack_start(main_stack, true, true, 0);

			var scroll = new Gtk.ScrolledWindow(null, null);
			main_stack.add_titled(scroll, "applets", _("Applets"));
			/* Dummy - no notifications right now */
			var not = new NotificationsView();
			main_stack.add_titled(not, "notifications", _("Notifications"));

			scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

			/* Eventually these guys get dynamically loaded */
			box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			scroll.add(box);

			cal = new CalendarWidget(raven_settings);
			box.pack_start(cal, false, false, 0);

			audio_output_widget = new Budgie.SoundWidget("output");
			box.pack_start(audio_output_widget, false, false, 0);

			audio_input_widget = new Budgie.SoundWidget("input");
			box.pack_start(audio_input_widget, false, false, 0);

			mpris = new MprisWidget();
			box.pack_start(mpris, false, false, 0);

			main_stack.notify["visible-child-name"].connect(on_name_change);
			set_clean();
			set_sound_widget_events();
		}

		private void set_sound_widget_events() {
			audio_output_widget.devices_state_changed.connect(() => { // When the Sound Output widget has devices
				on_raven_settings_changed(SHOW_SOUND_OUTPUT_WIDGET);
			});

			audio_input_widget.devices_state_changed.connect(() => { // When the Sound Input widget has devices
				on_raven_settings_changed(SHOW_MIC_INPUT_WIDGET);
			});
		}

		void on_name_change() {
			if (main_stack.get_visible_child_name() == "notifications") {
				Raven.get_instance().ReadNotifications();
			}
		}

		/**
		* on_raven_settings_changed will handle when the settings for Raven widgets have changed
		*/
		void on_raven_settings_changed(string key) {
			// This key is handled by the panel manager instead of Raven directly.
			// Moreover, it isn't a boolean so it logs a Critical message on the get_boolean() below.
			if (key == "raven-position") {
				return;
			}

			bool show_widget = raven_settings.get_boolean(key);

			/**
			* You're probably wondering why I'm not just setting a visible value here, and that's typically a good idea.
			* However, it causes weird focus and rendering issues even when has_visible_focus is set to false. I don't get it either, so we're doing this.
			*/
			if (key == "show-calendar-widget") { // Calendar
				cal.set_show(show_widget);
			} else if (key == SHOW_SOUND_OUTPUT_WIDGET) { // Sound Output
				if (audio_output_widget.has_devices()) { // If output has devices, so there's a point to showing in the first place
					audio_output_widget.set_show(show_widget);
				} else {
					audio_output_widget.set_show(false);
				}
			} else if (key == SHOW_MIC_INPUT_WIDGET) { // Sound Input
				if (audio_input_widget.has_devices()) { // If the input has devices
					audio_input_widget.set_show(show_widget);
				} else {
					audio_input_widget.set_show(false);
				}
			} else if (key == "show-mpris-widget") { // MPRIS
				mpris.set_show(show_widget);
			}

			requested_draw();
		}

		public void set_clean() {
			on_raven_settings_changed("show-calendar-widget");
			on_raven_settings_changed(SHOW_SOUND_OUTPUT_WIDGET);
			on_raven_settings_changed(SHOW_MIC_INPUT_WIDGET);
			on_raven_settings_changed("show-mpris-widget");
			main_stack.set_visible_child_name("applets");
		}
	}
}
