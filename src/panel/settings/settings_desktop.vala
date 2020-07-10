/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2020 Budgie Desktop Developers
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

    private Settings wm_pref_settings;
    private Gtk.SpinButton? workspace_count;

#if HAVE_NAUTILUS
    private Settings bg_settings;
    private Settings nautilus_settings;
    private Gtk.Switch switch_icons;
    private Gtk.Switch switch_home;
    private Gtk.Switch switch_network;
    private Gtk.Switch switch_trash;
    private Gtk.Switch switch_mounts;
#endif

    public DesktopPage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "desktop",
               title: _("Desktop"),
               display_weight: 1,
               icon_name: "preferences-desktop-wallpaper");

        var grid = new SettingsGrid();
        this.add(grid);

        wm_pref_settings = new Settings("org.gnome.desktop.wm.preferences"); // Set up our wm preferences Settings

#if HAVE_NAUTILUS
        /* Allow icons */
        switch_icons = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_icons,
            _("Desktop Icons"),
            _("Control whether to allow launchers and icons on the desktop.")));

        /* Hook up settings */
        bg_settings = new GLib.Settings("org.gnome.desktop.background");
        bg_settings.bind("show-desktop-icons", switch_icons, "active", SettingsBindFlags.DEFAULT);
        bg_settings.changed["show-desktop-icons"].connect(this.update_switches);

        /* Show home */
        switch_home = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_home,
            _("Home directory"),
            _("Add a shortcut to your home directory on the desktop.")));

        /* Show network */
        switch_network = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_network,
            _("Network servers"),
            _("Add a shortcut to your local network servers on the desktop.")));

        /* Show trash */
        switch_trash = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_trash,
            _("Trash"),
            _("Add a shortcut to the Trash directory on the desktop.")));

        /* Show volumes */
        switch_mounts = new Gtk.Switch();
        grid.add_row(new SettingsRow(switch_mounts,
            _("Mounted volumes"),
            _("Mounted volumes & drives will appear on the desktop.")));


        nautilus_settings = new GLib.Settings("org.gnome.nautilus.desktop");
        nautilus_settings.bind("home-icon-visible", switch_home, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("network-icon-visible", switch_network, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("trash-icon-visible", switch_trash, "active", SettingsBindFlags.DEFAULT);
        nautilus_settings.bind("volumes-visible", switch_mounts, "active", SettingsBindFlags.DEFAULT);

        update_switches();
#endif

        workspace_count = new Gtk.SpinButton.with_range(1, 8, 1); // Create our button, with a minimum of 1 workspace and max of 8
        workspace_count.set_value((double) wm_pref_settings.get_int("num-workspaces")); // Set our default value

        workspace_count.value_changed.connect(() => { // On value change
            int new_val = workspace_count.get_value_as_int(); // Get the value as an int

            if (new_val < 1) { // Ensure valid minimum
                new_val = 1;
                workspace_count.set_value(1.0); // Set as 1
            } else if (new_val > 8) { // Ensure valid maximum
                new_val = 8;
                workspace_count.set_value(8.0); // Set as 8
            }

            wm_pref_settings.set_int("num-workspaces", new_val); // Update num-workspaces
        });

        grid.add_row(new SettingsRow(workspace_count,
            _("Number of virtual desktops"),
            _("Number of virtual desktops / workspaces to create automatically on startup.")
        ));
    }

#if HAVE_NAUTILUS
    void update_switches()
    {

        bool b = bg_settings.get_boolean("show-desktop-icons");
        switch_home.sensitive = b;
        switch_network.sensitive = b;
        switch_trash.sensitive = b;
        switch_mounts.sensitive = b;
    }
#endif
    
} /* End class */

} /* End namespace */
