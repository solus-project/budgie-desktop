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
	* FontPage allows users to change aspects of the fonts used
	*/
	public class FontPage : Budgie.SettingsPage {
		private Gtk.FontButton? fontbutton_title;
		private Gtk.FontButton? fontbutton_document;
		private Gtk.FontButton? fontbutton_interface;
		private Gtk.FontButton? fontbutton_monospace;
		private Gtk.SpinButton? spinbutton_scaling;
		private Gtk.ComboBox combobox_hinting;
		private Gtk.ComboBox combobox_antialias;

		private Settings ui_settings;
		private Settings wm_settings;

#if !HAVE_GSD_40
		private Settings x_settings;
#endif

		public FontPage() {
			Object(group: SETTINGS_GROUP_APPEARANCE,
				content_id: "fonts",
				title: _("Fonts"),
				display_weight: 2,
				icon_name: "preferences-desktop-font");

			var grid = new SettingsGrid();
			this.add(grid);
			var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);

			/* Titlebar */
			fontbutton_title = new Gtk.FontButton();
			grid.add_row(new SettingsRow(fontbutton_title,
				_("Window Titles"),
				_("Set the font used in the titlebars of applications.")));
			group.add_widget(fontbutton_title);

			/* Documents */
			fontbutton_document = new Gtk.FontButton();
			grid.add_row(new SettingsRow(fontbutton_document,
				_("Documents"),
				_("Set the display font used by for documents.")));
			group.add_widget(fontbutton_document);

			/* Interface */
			fontbutton_interface = new Gtk.FontButton();
			grid.add_row(new SettingsRow(fontbutton_interface,
				_("Interface"),
				_("Set the primary font used by application controls.")));
			group.add_widget(fontbutton_interface);

			/* Monospace */
			fontbutton_monospace = new Gtk.FontButton();
			grid.add_row(new SettingsRow(fontbutton_monospace,
				_("Monospace"),
				_("Set the fixed-width font used by text dominant applications.")));
			group.add_widget(fontbutton_monospace);

			/* Text scaling */
			spinbutton_scaling = new Gtk.SpinButton.with_range(0.5, 3, 0.01);
			grid.add_row(new SettingsRow(spinbutton_scaling,
				_("Text scaling"),
				_("Set the text scaling factor.")));
			group.add_widget(spinbutton_scaling);

			Gtk.TreeIter iter;

			/* Hinting */
			combobox_hinting = new Gtk.ComboBox();
			var hinting_model = new Gtk.ListStore(2, typeof(string), typeof(string));
			string[] hinting_display = {
				_("Full"),
				_("Medium"),
				_("Slight"),
				_("None")
			};
			const string[] hinting_values = {
				"full",
				"medium",
				"slight",
				"none"
			};
			for (int i = 0; i < hinting_values.length; i++) {
				hinting_model.append(out iter);
				hinting_model.set(iter, 0, hinting_values[i], 1, hinting_display[i], -1);
			}
			combobox_hinting.set_model(hinting_model);
			combobox_hinting.set_id_column(0);

			grid.add_row(new SettingsRow(combobox_hinting,
				_("Hinting"),
				_("Set the type of hinting to use.")));
			group.add_widget(combobox_hinting);

			/* Antialiasing */
			combobox_antialias = new Gtk.ComboBox();
			var antialias_model = new Gtk.ListStore(2, typeof(string), typeof(string));
			string[] antialias_display = {
				_("Subpixel (for LCD screens)"),
				_("Standard (grayscale)"),
				_("None")
			};
			const string[] antialias_values = {
				"rgba",
				"grayscale",
				"none"
			};
			for (int i = 0; i < antialias_values.length; i++) {
				antialias_model.append(out iter);
				antialias_model.set(iter, 0, antialias_values[i], 1, antialias_display[i], -1);
			}
			combobox_antialias.set_model(antialias_model);
			combobox_antialias.set_id_column(0);

			grid.add_row(new SettingsRow(combobox_antialias,
				_("Antialiasing"),
				_("Set the type of antialiasing to use.")));
			group.add_widget(combobox_antialias);

			var render = new Gtk.CellRendererText();
			combobox_hinting.pack_start(render, true);
			combobox_hinting.add_attribute(render, "text", 1);
			combobox_antialias.pack_start(render, true);
			combobox_antialias.add_attribute(render, "text", 1);

			/* Hook up settings */
			ui_settings = new Settings("org.gnome.desktop.interface");
			wm_settings = new Settings("org.gnome.desktop.wm.preferences");
			ui_settings.bind("document-font-name", fontbutton_document, "font-name", SettingsBindFlags.DEFAULT);
			ui_settings.bind("font-name", fontbutton_interface, "font-name", SettingsBindFlags.DEFAULT);
			ui_settings.bind("monospace-font-name", fontbutton_monospace, "font-name", SettingsBindFlags.DEFAULT);
			wm_settings.bind("titlebar-font", fontbutton_title, "font-name", SettingsBindFlags.DEFAULT);
			ui_settings.bind("text-scaling-factor", spinbutton_scaling, "value", SettingsBindFlags.DEFAULT);

#if HAVE_GSD_40
			ui_settings.bind("font-antialiasing", combobox_antialias, "active-id", SettingsBindFlags.DEFAULT);
			ui_settings.bind("font-hinting", combobox_hinting, "active-id", SettingsBindFlags.DEFAULT);
#else
			x_settings = new Settings("org.gnome.settings-daemon.plugins.xsettings");
			x_settings.bind("hinting", combobox_hinting, "active-id", SettingsBindFlags.DEFAULT);
			x_settings.bind("antialiasing", combobox_antialias, "active-id", SettingsBindFlags.DEFAULT);
#endif
		}
	}
}
