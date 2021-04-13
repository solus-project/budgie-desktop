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
	public class SettingsItem : Gtk.Box {
		private Gtk.Image widget_icon;
		private Gtk.Label widget_label;

		/* Bindable for sorting */
		public int display_weight { public set ; public get; default = 0 ; }


		public string icon_name { public get ; public set ; }
		public string label {
			public get {
				return this.widget_label.get_text();
			}
			/* Force <big> usage on all plain gettext labels */
			public set {
				this.widget_label.set_markup(value);
			}
		}

		/* Allow sorting the header */
		public string group { public set; public get; }

		/* Assign a page */
		public string content_id { public set ; public get; }

		public SettingsItem(string group, string content_id, string label, string icon_name) {
			Object(orientation: Gtk.Orientation.HORIZONTAL,
				spacing: 0);

			widget_icon = new Gtk.Image();
			widget_icon.icon_size = Gtk.IconSize.DND;
			widget_icon.pixel_size = 32;

			widget_label = new Gtk.Label(label);
			widget_label.halign = Gtk.Align.START;
			widget_label.use_markup = true;

			/* Set up some margins */
			widget_label.margin_end = 24;
			widget_label.margin_start = 6;
			widget_icon.margin_end = 8;
			widget_icon.margin_start = 12;

			margin_top = 2;
			margin_bottom = 2;

			pack_start(widget_icon, false, false, 0);
			pack_start(widget_label, false, false, 0);

			/* Set everything up */
			this.bind_property("icon-name", widget_icon, "icon-name", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
			this.icon_name = icon_name;
			this.label = label;
			this.group = group;
			this.content_id = content_id;
		}
	}
}
