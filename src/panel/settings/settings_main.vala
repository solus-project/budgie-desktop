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
    HashTable<string,SettingsPage?> page_map;
    HashTable<string,SettingsItem?> sidebar_map;

    public Budgie.DesktopManager? manager { public set ; public get ; }


    public SettingsWindow(Budgie.DesktopManager? manager)
    {
        Object(type: Gtk.WindowType.TOPLEVEL,
               window_position: Gtk.WindowPosition.CENTER,
               manager: manager);

        header = new Gtk.HeaderBar();
        header.set_show_close_button(true);
        set_titlebar(header);

        group_map = new HashTable<string,string>(str_hash, str_equal);
        group_map["appearance"] = _("Appearance");
        group_map["panel"] = _("Panels");
        page_map = new HashTable<string,SettingsPage?>(str_hash, str_equal);
        sidebar_map = new HashTable<string,SettingsItem?>(str_hash, str_equal);

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

        /* We'll need to build panel items for each toplevel */
        this.manager.panel_added.connect(this.on_panel_added);
        this.manager.panel_deleted.connect(this.on_panel_deleted);

        layout.show_all();
        header.show_all();
    }

    /**
     * Static pages that will always be part of the UI
     */
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
        scroll.show();

        page.bind_property("title", settings_item, "label", BindingFlags.DEFAULT);

        this.sidebar_map[page.content_id] = settings_item;
        this.page_map[page.content_id] = page;
        content.add_named(scroll, page.content_id);
    }

    /**
     * Remove a page from the sidebar and content stack
     */
    void remove_page(string content_id)
    {
        Budgie.SettingsPage? page = this.page_map.lookup(content_id);
        Budgie.SettingsItem? item = this.sidebar_map.lookup(content_id);

        /* Remove from listbox */
        if (item != null) {
            item.get_parent().destroy();
        }

        /* Remove from content view */
        if (page != null) {
            page.destroy();
        }
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
            Gtk.Label label = new Gtk.Label(title);
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

    /**
     * New panel added, let's make a page for it
     */
    private void on_panel_added(string uuid, Budgie.Toplevel? toplevel)
    {
        string content_id = "panel-" + uuid;
        if (content_id in this.page_map) {
            return;
        }
        this.add_page(new PanelPage(this.manager, toplevel));
    }

    /**
     * A panel was destroyed, remove our knowledge of it
     */
    private void on_panel_deleted(string uuid)
    {
        /* Nuke from orbit */
        this.remove_page("panel-" + uuid);
    }
} /* End SettingsWindow */


} /* End namespace Budgie */
