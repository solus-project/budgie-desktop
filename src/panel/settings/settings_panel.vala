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
 * PanelPage allows users to change aspects of the fonts used
 */
public class PanelPage : Budgie.SettingsPage {

    unowned Budgie.Toplevel? toplevel;
    Gtk.Stack stack;
    Gtk.StackSwitcher switcher;

    public PanelPage(Budgie.Toplevel? toplevel)
    {
        Object(group: SETTINGS_GROUP_PANEL,
               content_id: "panel-%s".printf(toplevel.uuid),
               title: PanelPage.get_panel_name(toplevel),
               icon_name: "gnome-panel");

        this.toplevel = toplevel;

        /* Main layout bits */
        switcher = new Gtk.StackSwitcher();
        stack = new Gtk.Stack();
        switcher.set_stack(stack);
        this.pack_start(switcher, false, false, 0);
        this.pack_start(stack, true, true, 0);

        this.stack.add_titled(this.applets_page(), "main", _("Applets"));
        this.stack.add_titled(this.settings_page(), "applets", _("Settings"));

        this.show_all();
    }

    /**
     * Determine a human readable named based on the panel's position on screen
     * For brownie points we'll identify docks differently
     */
    static string get_panel_name(Budgie.Toplevel? panel)
    {
        if (panel.dock_mode) {
            switch (panel.position) {
                case PanelPosition.TOP:
                    return _("Top Dock");
                case PanelPosition.RIGHT:
                    return _("Right Dock");
                case PanelPosition.LEFT:
                    return _("Left Dock");
                default:
                    return _("Bottom Dock");
            }
        } else {
            switch (panel.position) {
                case PanelPosition.TOP:
                    return _("Top Panel");
                case PanelPosition.RIGHT:
                    return _("Right Panel");
                case PanelPosition.LEFT:
                    return _("Left Panel");
                default:
                    return _("Bottom Panel");
            }
        }
    }

    private Gtk.Widget? settings_page()
    {
        return new SettingsGrid();
    }

    private Gtk.Widget? applets_page()
    {
        return new SettingsGrid();
    }
    
} /* End class */

} /* End namespace */
