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
	public class Plugin : Budgie.Plugin, Peas.ExtensionBase {
		public Budgie.Applet get_panel_widget(string uuid) {
			return new Applet(uuid);
		}
	}

	public class Applet : Budgie.Applet {
		private Gtk.EventBox event_box;
		private Gtk.Image? applet_icon;

		private Budgie.Popover? popover = null;
		private unowned Budgie.PopoverManager? manager = null;

		private Settings? interface_settings;
		private Settings? settings;

		private ThemedIcon? caffeine_full_cup;
		private ThemedIcon? caffeine_empty_cup;

		public string uuid { public set; public get; }

		public Applet(string uuid) {
			Object(uuid: uuid);

			interface_settings = new Settings("org.gnome.desktop.interface"); // Get the GNOME Desktop interface
			settings = new Settings("com.solus-project.budgie-wm"); // Get the window manager settings

			caffeine_full_cup = new ThemedIcon.from_names( {"caffeine-cup-full", "budgie-caffeine-cup-full" });
			caffeine_empty_cup = new ThemedIcon.from_names( {"caffeine-cup-empty", "budgie-caffeine-cup-empty" });

			event_box = new Gtk.EventBox();
			this.add(event_box);
			applet_icon = new Gtk.Image.from_gicon(get_current_mode_icon(), Gtk.IconSize.MENU);
			event_box.add(applet_icon);

			popover = new CaffeineWindow(event_box, settings);

			settings.changed["caffeine-mode"].connect(() => { // When Caffeine Mode has been enabled or disabled
				update_icon(); // Update the icon
			});

			interface_settings.changed["icon-theme"].connect_after(() => {
				Timeout.add(200, () => {
					set_caffeine_icons(); // Update our Caffeine Icons
					update_icon(); // Update the icon
					return false;
				});
			});

			// On click icon
			event_box.button_press_event.connect((e) => {
				switch (e.button) {
				case 1:
					if (popover.get_visible()) {
						popover.hide();
					} else {
						popover.show_all();
						this.manager.show_popover(event_box);
					}
					break;
				case 2:
					toggle_caffeine_mode(); // Toggle the caffeine mode
					break;
				default:
					return Gdk.EVENT_PROPAGATE;
				}

				return Gdk.EVENT_STOP;
			});

			this.show_all();
		}

		/**
		* get_current_mode_icon will get the current ThemedIcon (GIcon) for the current Caffeine Mode state
		*/
		private ThemedIcon get_current_mode_icon() {
			bool enabled = settings.get_boolean("caffeine-mode"); // Get our boolean determining if caffeine mode is enabled
			ThemedIcon state_icon = (enabled) ? caffeine_full_cup : caffeine_empty_cup;
			return state_icon;
		}

		/**
		* toggle_caffeine_mode will toggle our current Caffeine Mode
		*/
		private void toggle_caffeine_mode() {
			bool enabled = settings.get_boolean("caffeine-mode");
			settings.set_boolean("caffeine-mode", !enabled); // Invert current value
		}

		/**
		* set_caffeine_icons will set our full and empty cup icons to the current IconTheme icons
		*/
		private void set_caffeine_icons() {
			caffeine_full_cup = new ThemedIcon.from_names( {"caffeine-cup-full", "budgie-caffeine-cup-full" });
			caffeine_empty_cup = new ThemedIcon.from_names( {"caffeine-cup-empty", "budgie-caffeine-cup-empty" });
		}

		/**
		* update_icon will update the applet icon
		*/
		private void update_icon() {
			applet_icon.set_from_gicon(get_current_mode_icon(), Gtk.IconSize.MENU); // Update our icon
		}

		public override void update_popovers(Budgie.PopoverManager? manager) {
			manager.register_popover(event_box, popover);
			this.manager = manager;
		}

		public override bool supports_settings() {
			return true;
		}

		public override Gtk.Widget? get_settings_ui() {
			return new AppletSettings(this.get_applet_settings(uuid));
		}
	}
}

[ModuleInit]
public void peas_register_types(TypeModule module) {
	// boilerplate - all modules need this
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(Caffeine.Plugin));
}
