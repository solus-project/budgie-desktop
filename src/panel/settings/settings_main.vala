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
    HashTable<string,string> group_map;

    public SettingsWindow()
    {
        Object(type: Gtk.WindowType.TOPLEVEL,
               window_position: Gtk.WindowPosition.CENTER);

        header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        set_titlebar(header);

        group_map = new HashTable<string,string>(str_hash, str_equal);
        group_map["appearance"] = _("Appearance");

        /* Don't die when closed. */
        delete_event.connect(this.hide_on_delete);

        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);

        /* Have to override wmclass for pinning support */
        set_title(_("Budgie Settings"));
        set_wmclass("budgie-settings", "budgie-settings");
        set_icon_name("preferences-desktop");

        /* Fit even on a spud resolution */
        set_default_size(750, 550);

        /* Sidebar navigation */
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        sidebar = new Gtk.ListBox();
        sidebar.set_header_func(this.do_headers);
        sidebar.row_selected.connect(this.on_row_selected);
        sidebar.set_activate_on_single_click(true);
        scroll.add(sidebar);
        layout.pack_start(scroll, false, false, 0);
        scroll.margin_end = 24;

        /* Where actual Things go */
        content = new Gtk.Stack();
        content.set_homogeneous(false);
        content.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
        layout.pack_start(content, true, true, 0);

        /* Help our theming community out */
        get_style_context().add_class("budgie-settings-window");
        content.get_style_context().add_class("view");
        content.get_style_context().add_class("content-view");
        sidebar.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);

        this.build_content();

        layout.show_all();
        header.show_all();
    }

    void build_content()
    {
        this.add_page(new Budgie.StylePage());
        this.add_page(new Budgie.FontPage());
        this.add_page(new Budgie.WindowsPage());
    }

    /**
     * Handle transition between various pages
     */
    void on_row_selected(Gtk.ListBoxRow? row)
    {
        if (row == null) {
            return;
        }
        SettingsItem? item = row.get_child() as SettingsItem;
        this.content.set_visible_child_name(item.content_id);
    }

    /**
     * Add a new page to our sidebar + stack
     */
    void add_page(Budgie.SettingsPage? page)
    {
        var settings_item = new SettingsItem(page.group, page.content_id, page.title, page.icon_name);
        settings_item.show_all();
        sidebar.add(settings_item);

        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroll.add(page);

        content.add_named(scroll, page.content_id);
    }

    /**
     * Provide categorisation for our sidebar items
     */
    void do_headers(Gtk.ListBoxRow? before, Gtk.ListBoxRow? after)
    {
        SettingsItem? child = null;
        string? prev = null;
        string? next = null;

        if (before != null) {
            child = before.get_child() as SettingsItem;
            prev = child.group;
        }

        if (after != null) {
            child = after.get_child() as SettingsItem;
            next = child.group;
        }

        if (after == null || prev != next) {
            string? title = group_map.lookup(prev);
            Gtk.Label label = new Gtk.Label("<big>%s</big>".printf(title));
            label.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);
            label.halign = Gtk.Align.START;
            label.use_markup = true;
            label.margin_top = 6;
            label.margin_bottom = 6;
            label.margin_start = 6;
            before.set_header(label);
        } else {
            before.set_header(null);
        }
    }
} /* End SettingsWindow */


} /* End namespace Budgie */
