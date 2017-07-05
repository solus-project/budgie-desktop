/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * DesktopPage allows users to change aspects of the fonts used
 */
public class DesktopPage : Budgie.SettingsPage {

    private GLib.Settings bg_settings;
    private GLib.Settings nautilus_settings;

    private Gtk.Switch switch_icons;
    private Gtk.Switch switch_home;
    private Gtk.Switch switch_network;
    private Gtk.Switch switch_trash;
    private Gtk.Switch switch_mounts;


    public DesktopPage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "desktop",
               title: _("Desktop"),
               display_weight: 1,
               icon_name: "preferences-desktop-wallpaper");

        var grid = new SettingsGrid();
        this.add(grid);

        /* Allow icons */
        switch_icons = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_icons,
            _("Desktop Icons"),
            _("Control whether to allow launchers and icons on the desktop")));

        /* Show home */
        switch_home = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_home,
            _("Home directory"),
            _("Add a shortcut to your home directory on the desktop")));

        /* Show network */
        switch_network = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_network,
            _("Network servers"),
            _("Add a shortcut to your local network servers on the desktop")));

        /* Show trash */
        switch_trash = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_trash,
            _("Trash"),
            _("Add a shortcut to the Trash directory on the desktop")));

        /* Show volumes */
        switch_mounts = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_mounts,
            _("Mounted volumes"),
            _("Mounted volumes & drives will appear on the desktop")));

        /* Hook up settings */
        bg_settings = new GLib.Settings("org.gnome.desktop.background");
        nautilus_settings = new GLib.Settings("org.gnome.nautilus.desktop");

        bg_settings.bind("show-desktop-icons", switch_icons, "active", SettingsBindFlags.DEFAULT);

        bg_settings.changed["show-desktop-icons"].connect(this.update_switches);

        nautilus_settings.bind("home-icon-visible", switch_home, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("network-icon-visible", switch_network, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("trash-icon-visible", switch_trash, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("volumes-visible", switch_mounts, "active", SettingsBindFlags.DEFAULT);

        update_switches();
    }

    void update_switches()
    {
        bool b = bg_settings.get_boolean("show-desktop-icons");
        switch_home.sensitive = b;
        switch_network.sensitive = b;
        switch_trash.sensitive = b;
        switch_mounts.sensitive = b;
    }
    
} /* End class */

} /* End namespace */
