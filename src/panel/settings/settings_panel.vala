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
        /* TODO: Set the right panel name .. */
        Object(group: SETTINGS_GROUP_PANEL,
               content_id: "panel",
               title: _("Panel"),
               icon_name: "gnome-panel");

        this.toplevel = toplevel;

        /* Main layout bits */
        switcher = new Gtk.StackSwitcher();
        stack = new Gtk.Stack();
        switcher.set_stack(stack);
        this.pack_start(switcher, false, false, 0);
        this.pack_start(stack, true, true, 0);

        this.stack.add_titled(this.main_page(), "main", _("Settings"));
        this.stack.add_titled(this.applets_page(), "main", _("Applets"));
    }

    private Gtk.Widget? main_page()
    {
        return new SettingsGrid();
    }

    private Gtk.Widget? applets_page()
    {
        return new SettingsGrid();
    }
    
} /* End class */

} /* End namespace */
