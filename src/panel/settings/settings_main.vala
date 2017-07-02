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

public class SettingsWindow : Gtk.Window {

    Gtk.HeaderBar header;
    Gtk.ListBox sidebar;
    Gtk.Stack content;
    Gtk.Box layout;

    public SettingsWindow()
    {
        Object(type: Gtk.WindowType.TOPLEVEL,
               window_position: Gtk.WindowPosition.CENTER);

        header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        set_titlebar(header);

        /* Don't die when closed. */
        delete_event.connect(this.hide_on_delete);

        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);

        /* Have to override wmclass for pinning support */
        set_title(_("Budgie Settings"));
        set_wmclass("budgie-settings", "budgie-settings");
        set_icon_name("preferences-desktop");

        /* Fit even on a spud resolution */
        set_size_request(750, 550);

        /* Sidebar navigation */
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        sidebar = new Gtk.ListBox();
        scroll.add(sidebar);
        layout.pack_start(scroll, false, false, 0);
        scroll.margin_end = 40;

        /* Where actual Things go */
        content = new Gtk.Stack();
        layout.pack_start(content, true, true, 0);

        /* Help our theming community out */
        get_style_context().add_class("budgie-settings-window");
        content.get_style_context().add_class("view");
        content.get_style_context().add_class("content-view");
        sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);

        this.dummy_content();

        layout.show_all();
        header.show_all();
    }

    void dummy_content()
    {
        this.add_page(new Budgie.ThemePage());
    }


    /**
     * Add a new page to our sidebar + stack
     */
    void add_page(Budgie.SettingsPage? page)
    {
        var settings_item = new SettingsItem(page.group, page.content_id, page.title, page.icon_name);
        settings_item.show_all();
        sidebar.add(settings_item);

        content.add_named(page, page.content_id);
    }

} /* End SettingsWindow */


} /* End namespace Budgie */
