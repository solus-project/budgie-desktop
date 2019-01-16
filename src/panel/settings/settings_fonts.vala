/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
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

    private GLib.Settings ui_settings;
    private GLib.Settings wm_settings;


    public FontPage()
    {
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

        /* Hook up settings */
        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        wm_settings = new GLib.Settings("org.gnome.desktop.wm.preferences");
        ui_settings.bind("document-font-name", fontbutton_document, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("font-name", fontbutton_interface, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("monospace-font-name", fontbutton_monospace, "font-name", SettingsBindFlags.DEFAULT);
        wm_settings.bind("titlebar-font", fontbutton_title, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("text-scaling-factor", spinbutton_scaling, "value", SettingsBindFlags.DEFAULT);
    }

} /* End class */

} /* End namespace */
