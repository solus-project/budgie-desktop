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
	public const string SETTINGS_GROUP_APPEARANCE = "appearance";
	public const string SETTINGS_GROUP_PANEL = "panel";
	public const string SETTINGS_GROUP_SESSION = "session";

	/**
	* A SettingsRow is used to control the content layout in a SettingsPage
	* to ensure everyone conforms to the page grid
	*/
	public class SettingsRow : GLib.Object {
		public Gtk.Widget widget { construct set ; public get; }
		public string? label { construct set ; public get; }
		public string? description { construct set ; public get; }

		/* Convenience */
		public SettingsRow(Gtk.Widget? widget, string? label, string? description = null) {
			this.widget = widget;
			this.label = label;
			this.description = description;
		}
	}

	/**
	* A settings grid is just a helper with some methods to add new setting items
	* easily without buggering about with the internals of GtkGrids
	*/
	public class SettingsGrid : Gtk.Grid {
		public int current_row = 0;
		public bool small_mode = false;

		/**
		* Add a new row into this SettingsPage, taking ownership of the row
		* content and widgets.
		*/
		public void add_row(SettingsRow? row) {
			Gtk.Label? lab_main = null;

			if (row.label != null) {
				lab_main = new Gtk.Label(row.label);
				lab_main.halign = Gtk.Align.START;
				lab_main.margin_top = 12;
				lab_main.hexpand = true;
				attach(lab_main, 0, current_row, 1, 1);
				attach(row.widget, 1, current_row, 1, row.description == null ? 1 : 2);
			} else {
				attach(row.widget, 0, current_row, 2, row.description == null ? 1 : 2);
			}

			row.widget.halign = Gtk.Align.END;
			row.widget.valign = Gtk.Align.CENTER;
			row.widget.vexpand = false;

			row.widget.margin_start = small_mode ? 8 : 28;
			row.widget.margin_top = 12;

			++current_row;

			if (row.description == null) {
				return;
			}

			var desc_lab = new Gtk.Label(row.description);
			desc_lab.halign = Gtk.Align.START;
			desc_lab.margin_end = small_mode ? 12 : 40;

			/* Deprecated but we need this to make line wrap actually work */
			desc_lab.set_property("xalign", 0.0);
			desc_lab.set_line_wrap(true);
			desc_lab.set_line_wrap_mode(Pango.WrapMode.WORD);

			desc_lab.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);

			attach(desc_lab, 0, current_row, 1, 1);

			++current_row;
		}
	}

	/**
	* A base SettingsPage exposes properties to allow it to fit into the UI
	* and sidebar navigation
	*/
	public class SettingsPage : Gtk.Box {
		/* Allow sorting the header */
		public string group { public set; public get; }

		/* Assign a page */
		public string content_id { public set ; public get; }

		/* The icon we want in the sidebar */
		public string icon_name { public set; public get; }

		/* The title to display in the sidebar */
		public string title { public set ; public get; }

		/* If we want to be automatically wrapped in a scrolled window */
		public bool want_scroll { public set; public get; default = true; }

		/* Control the display weight in the sidebar, i.e. where it list */
		public int display_weight { public set; public get; default = 0; }

		construct {
			orientation = Gtk.Orientation.VERTICAL;
			border_width = 20;
			margin_end = 24;
			halign = Gtk.Align.CENTER;
			valign = Gtk.Align.FILL;
			get_style_context().add_class("settings-page");
		}
	}
}
