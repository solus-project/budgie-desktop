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
	* StylePage simply provides a bunch of theme controls
	*/
	public class StylePage : Budgie.SettingsPage {
		private Gtk.ComboBox? combobox_gtk;
		private Gtk.ComboBox? combobox_icon;
		private Gtk.ComboBox? combobox_cursor;
		private Gtk.ComboBox? combobox_notification_position;
		private Gtk.Switch? switch_dark;
		private Gtk.Switch? switch_builtin;
		private Gtk.Switch? switch_animations;
		private Settings ui_settings;
		private Settings budgie_settings;
		private SettingsRow? builtin_row;
		private ThemeScanner? theme_scanner;

		public StylePage() {
			Object(group: SETTINGS_GROUP_APPEARANCE,
				content_id: "style",
				title: _("Style"),
				display_weight: 0,
				icon_name: "preferences-desktop-theme"
			);

			budgie_settings = new Settings("com.solus-project.budgie-panel");
			ui_settings = new Settings("org.gnome.desktop.interface");

			var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
			var grid = new SettingsGrid();
			this.add(grid);

			combobox_gtk = new Gtk.ComboBox();
			grid.add_row(new SettingsRow(combobox_gtk,
				_("Widgets"),
				_("Set the appearance of window decorations and controls")));

			combobox_icon = new Gtk.ComboBox();
			grid.add_row(new SettingsRow(combobox_icon,
				_("Icons"),
				_("Set the globally used icon theme")));

			combobox_cursor = new Gtk.ComboBox();
			grid.add_row(new SettingsRow(combobox_cursor,
				_("Cursors"),
				_("Set the globally used mouse cursor theme")));

			combobox_notification_position = new Gtk.ComboBox();
			grid.add_row(new SettingsRow(combobox_notification_position,
				_("Notification Position"),
				_("Set the location for notification popups")));

			/* Stick the combos in a size group */
			group.add_widget(combobox_gtk);
			group.add_widget(combobox_icon);
			group.add_widget(combobox_cursor);
			group.add_widget(combobox_notification_position);

			switch_dark = new Gtk.Switch();
			grid.add_row(new SettingsRow(switch_dark, _("Dark theme")));

			bool show_builtin = budgie_settings.get_boolean("show-builtin-theme-option");

			if (show_builtin) {
				switch_builtin = new Gtk.Switch();
				builtin_row = new SettingsRow(switch_builtin,
				_("Built-in theme"),
				_("When enabled, the built-in theme will override the desktop component styling"));

				grid.add_row(builtin_row);
			}

			switch_animations = new Gtk.Switch();
			grid.add_row(new SettingsRow(switch_animations,
				_("Animations"),
				_("Control whether windows and controls use animations")));

			/* Add options for notification position */
			var model = new Gtk.ListStore(3, typeof(string), typeof(string), typeof(Budgie.NotificationPosition));

			Gtk.TreeIter iter;
			const Budgie.NotificationPosition[] positions = {
				Budgie.NotificationPosition.TOP_LEFT,
				Budgie.NotificationPosition.TOP_RIGHT,
				Budgie.NotificationPosition.BOTTOM_LEFT,
				Budgie.NotificationPosition.BOTTOM_RIGHT
			};

			foreach (var pos in positions) {
				model.append(out iter);
				model.set(iter, 0, pos.to_string(), 1, notification_position_to_display(pos), 2, pos, -1);
			}

			combobox_notification_position.set_model(model);
			combobox_notification_position.set_id_column(0);

			/* Sort out renderers for all of our dropdowns */
			var render = new Gtk.CellRendererText();
			combobox_gtk.pack_start(render, true);
			combobox_gtk.add_attribute(render, "text", 0);
			combobox_icon.pack_start(render, true);
			combobox_icon.add_attribute(render, "text", 0);
			combobox_cursor.pack_start(render, true);
			combobox_cursor.add_attribute(render, "text", 0);
			combobox_notification_position.pack_start(render, true);
			combobox_notification_position.add_attribute(render, "text", 1);

			/* Hook up settings */
			budgie_settings.bind("dark-theme", switch_dark, "active", SettingsBindFlags.DEFAULT);

			if (show_builtin) {
				budgie_settings.bind("builtin-theme", switch_builtin, "active", SettingsBindFlags.DEFAULT);
			}

			budgie_settings.bind("notification-position", combobox_notification_position, "active-id", SettingsBindFlags.DEFAULT);
			ui_settings.bind("enable-animations", switch_animations, "active", SettingsBindFlags.DEFAULT);
			this.theme_scanner = new ThemeScanner();

			Idle.add(() => {
				this.load_themes();
				return false;
			});
		}

		public void load_themes() {
			/* Scan the themes */
			this.theme_scanner.scan_themes.begin(() => {
				/* Gtk themes */ {
					Gtk.TreeIter iter;
					var model = new Gtk.ListStore(1, typeof(string));
					bool hit = false;
					foreach (var theme in theme_scanner.get_gtk_themes()) {
						model.append(out iter);
						model.set(iter, 0, theme, -1);
						hit = true;
					}
					combobox_gtk.set_model(model);
					combobox_gtk.set_id_column(0);
					model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
					if (hit) {
						combobox_gtk.sensitive = true;
						ui_settings.bind("gtk-theme", combobox_gtk, "active-id", SettingsBindFlags.DEFAULT);
						combobox_gtk.active_id = ui_settings.get_string("gtk-theme");
					}
				}
				/* Icon themes */ {
					Gtk.TreeIter iter;
					var model = new Gtk.ListStore(1, typeof(string));
					bool hit = false;
					foreach (var theme in theme_scanner.get_icon_themes()) {
						model.append(out iter);
						model.set(iter, 0, theme, -1);
						hit = true;
					}
					combobox_icon.set_model(model);
					combobox_icon.set_id_column(0);
					model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
					if (hit) {
						combobox_icon.sensitive = true;
						ui_settings.bind("icon-theme", combobox_icon, "active-id", SettingsBindFlags.DEFAULT);
						combobox_icon.active_id = ui_settings.get_string("icon-theme");
					}
				}

				/* Cursor themes */ {
					Gtk.TreeIter iter;
					var model = new Gtk.ListStore(1, typeof(string));
					bool hit = false;
					foreach (var theme in theme_scanner.get_cursor_themes()) {
						model.append(out iter);
						model.set(iter, 0, theme, -1);
						hit = true;
					}
					combobox_cursor.set_model(model);
					combobox_cursor.set_id_column(0);
					model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
					if (hit) {
						combobox_cursor.sensitive = true;
						ui_settings.bind("cursor-theme", combobox_cursor, "active-id", SettingsBindFlags.DEFAULT);
						combobox_cursor.active_id = ui_settings.get_string("cursor-theme");
					}
				}
				queue_resize();
			});
		}

		/**
		* Get a user-friendly name for each position.
		*/
		public string notification_position_to_display(Budgie.NotificationPosition position) {
			switch (position) {
				case NotificationPosition.TOP_LEFT:
					return _("Top Left");
				case NotificationPosition.BOTTOM_LEFT:
					return _("Bottom Left");
				case NotificationPosition.BOTTOM_RIGHT:
					return _("Bottom Right");
				case NotificationPosition.TOP_RIGHT:
				default:
					return _("Top Right");
			}
		}
	}
}
