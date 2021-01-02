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

namespace Caffeine {
	public class CaffeineWindow : Budgie.Popover {
		private Gtk.Switch? mode = null;
		private Gtk.SpinButton? timer = null;
		private ulong mode_id;
		private ulong timer_id;

		/**
		* Unowned variables
		*/
		private unowned Settings? settings;

		public CaffeineWindow(Gtk.Widget? c_parent, Settings? c_settings) {
			Object(relative_to: c_parent);
			settings = c_settings;
			get_style_context().add_class("caffeine-popover");

			var container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			container.get_style_context().add_class("container");

			Gtk.Grid grid = new Gtk.Grid(); // Construct our new grid
			grid.set_row_spacing(6);
			grid.set_column_spacing(12);

			// Prepare label widget
			Gtk.Label caffeine_mode_label = new Gtk.Label(_("Caffeine Mode"));
			caffeine_mode_label.set_halign(Gtk.Align.START);
			Gtk.Label timer_label = new Gtk.Label(_("Timer (minutes)"));
			timer_label.set_halign(Gtk.Align.START);

			// Prepare control widget
			mode = new Gtk.Switch();
			mode.set_halign(Gtk.Align.END);
			var adjustment = new Gtk.Adjustment(0, 0, 1440, 1, 10, 0);
			timer = new Gtk.SpinButton(adjustment, 0, 0);
			timer.set_halign(Gtk.Align.END);

			// Attach widgets
			grid.attach(caffeine_mode_label, 0, 0);
			grid.attach(timer_label, 0, 1);
			grid.attach(mode, 1, 0);
			grid.attach(timer, 1, 1);

			container.add(grid);
			add(container);

			update_ux_state(); // Set our initial toggle value

			settings.changed["caffeine-mode"].connect(() => { // On Caffeine Mode schema change
				update_ux_state(); // Update our toggle
			});

			settings.changed["caffeine-mode-timer"].connect(() => { // On Caffeine Mode Timer value change
				SignalHandler.block(timer, timer_id);
				update_ux_state();
				SignalHandler.unblock(timer, timer_id);
			});

			mode_id = mode.notify["active"].connect(() => { // On active change
				SignalHandler.block(mode, mode_id); // Block to prevent update on set_caffeine_mode schema change
				timer.sensitive = !mode.active; // Set timer sensitivity
				settings.set_boolean("caffeine-mode", mode.active); // Update our caffeine-mode WM setting
				SignalHandler.unblock(mode, mode_id);
			});

			timer_id = timer.value_changed.connect(update_timer_value);
		}

		/**
		* update_ux_state will set our switch active state to the current Caffeine Mode value and toggle timer
		*/
		public void update_ux_state() {
			mode.active = settings.get_boolean("caffeine-mode"); // Set our Caffeine Mode active state
			timer.sensitive = !mode.active; // Set timer sensitivity
			timer.value = settings.get_int("caffeine-mode-timer");
		}

		public void toggle_applet() {
			mode.active = !mode.active;
		}

		/**
		* update_timer_value will update our settings timer value based on our SpinButton change
		*/
		public void update_timer_value() {
			var time = timer.get_value_as_int();
			settings.set_int("caffeine-mode-timer", time); // Update our caffeine-mode-timer value
		}
	}
}
