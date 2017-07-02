/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
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

    private GLib.Settings ui_settings;
    private GLib.Settings wm_settings;


    public FontPage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "fonts",
               title: _("Fonts"),
               icon_name: "preferences-desktop-fonts");

        var group = new Gtk.SizeGroup(Gtk.SizeGroupMode.BOTH);

        /* Titlebar */
        fontbutton_title = new Gtk.FontButton();
        this.add_row(new SettingsRow(fontbutton_title, _("Window Titles")));
        group.add_widget(fontbutton_title);

        /* Documents */
        fontbutton_document = new Gtk.FontButton();
        this.add_row(new SettingsRow(fontbutton_document, _("Documents")));
        group.add_widget(fontbutton_document);

        /* Interface */
        fontbutton_interface = new Gtk.FontButton();
        this.add_row(new SettingsRow(fontbutton_interface, _("Interface")));
        group.add_widget(fontbutton_interface);

        /* Monospace */
        fontbutton_monospace = new Gtk.FontButton();
        this.add_row(new SettingsRow(fontbutton_monospace, _("Monospace")));
        group.add_widget(fontbutton_monospace);

        /* Hook up settings */
        ui_settings = new GLib.Settings("org.gnome.desktop.interface");
        wm_settings = new GLib.Settings("org.gnome.desktop.wm.preferences");
        ui_settings.bind("document-font-name", fontbutton_document, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("font-name", fontbutton_interface, "font-name", SettingsBindFlags.DEFAULT);
        ui_settings.bind("monospace-font-name", fontbutton_monospace, "font-name", SettingsBindFlags.DEFAULT);
        wm_settings.bind("titlebar-font", fontbutton_title, "font-name", SettingsBindFlags.DEFAULT);
    }
    
} /* End class */

} /* End namespace */
