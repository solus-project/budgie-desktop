/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

/**
 * Simple wrapper widget to allow us to insert and sort listboxrows
 */
public class IconContextLabel : Gtk.ListBoxRow
{
    public string category;

    Gtk.Label label;

    public IconContextLabel(string text)
    {
        Object();
        label = new Gtk.Label(text);
        add(label);
        label.halign = Gtk.Align.START;
        label.show_all();
        category = text;

        /* PLEASE COMPLAIN IF THIS CAUSES ISSUES! */
        margin = 4;
        margin_start = 8;
        margin_end = 8;
    }
}

/**
 * IconChooser is a very trivial dialog that allows users to dynamically
 * select an icon from the icon theme or from a given file path
 */
public class IconChooser : Gtk.Dialog
{

    Gtk.Stack stack;
    Gtk.StackSwitcher switcher;
    string? icon_pick = null;
    Gtk.Button button_set_icon;
    Gtk.ListBox listbox_contexts;
    Gtk.IconView iconview_icons;
    Gtk.TreeModelFilter filter_model;
    Gtk.ListStore icon_model;
    string? active_category = null;
    HashTable<string,bool> hit_set;

    /**
     * Construct a new modal IconChooser with the given parent
     */
    public IconChooser(Gtk.Window parent)
    {
        Object(transient_for: parent,
               modal: true,
               use_header_bar: 1);

        get_style_context().add_class("budgie-icon-chooser");
        hit_set = new HashTable<string,bool>(str_hash, str_equal);

        add_button(_("Cancel"), Gtk.ResponseType.CANCEL);
        button_set_icon = add_button(_("Set icon"), Gtk.ResponseType.ACCEPT) as Gtk.Button;
        button_set_icon.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        switcher = new Gtk.StackSwitcher();
        (get_header_bar() as Gtk.HeaderBar).set_custom_title(switcher);
        stack = new Gtk.Stack();
        stack.set_homogeneous(false);
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        switcher.set_stack(stack);

        (get_content_area() as Gtk.Box).pack_start(stack, true, true, 0);

        this.create_icon_area();
        this.create_file_area();

        switcher.show_all();

        get_content_area().show_all();
        get_header_bar().show_all();
    }

    /**
     * Create an icon chooser UI
     */
    void create_icon_area()
    {
        var w = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);

        /* Fix up the sidebar */
        listbox_contexts = new Gtk.ListBox();
        listbox_contexts.get_style_context().add_class(Gtk.STYLE_CLASS_SIDEBAR);
        listbox_contexts.set_activate_on_single_click(true);
        listbox_contexts.set_selection_mode(Gtk.SelectionMode.SINGLE);
        listbox_contexts.set_sort_func(this.sort_sidebar);
        listbox_contexts.row_activated.connect(this.row_activated);
        scroll.add(listbox_contexts);
        w.pack_start(scroll, false, false, 0);

        /* Give us a sidebar listing */
        foreach (var context in Gtk.IconTheme.get_default().list_contexts()) {
            var label = new IconContextLabel(context);
            listbox_contexts.add(label);
            label.show_all();
        }

        icon_model = new Gtk.ListStore(3, typeof(Gdk.Pixbuf), typeof(string), typeof(string));
        filter_model = new Gtk.TreeModelFilter(icon_model, null);
        filter_model.set_visible_func(this.filter_model_func);
        iconview_icons = new Gtk.IconView();
        scroll = new Gtk.ScrolledWindow(null, null);
        scroll.add(iconview_icons);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        w.pack_start(scroll, true, true, 0);
        iconview_icons.set_model(filter_model);
        iconview_icons.set_pixbuf_column(0);
        iconview_icons.set_markup_column(1);

        /* Stuff it into the UI */
        this.stack.add_titled(w, "icons", _("Icon theme"));
        w.show_all();
    }

    void row_activated(Gtk.ListBoxRow? row)
    {
        if (row == null) {
            active_category = null;
        } else {
            active_category = "" + (row as IconContextLabel).category;
            if (!this.hit_set.lookup(active_category)) {
                this.hit_set[active_category] = true;
                this.load_icons.begin(active_category);
            }
        }
        /* Ensure we're properly filtered */
        this.filter_model.refilter();
    }

    bool filter_model_func(Gtk.TreeModel model, Gtk.TreeIter iter)
    {
        string? context = null;
        model.get(iter, 2, out context, -1);
        if (context == null || context != this.active_category) {
            return false;
        }
        return true;
    }

    /**
     * Load icons on the idle callback
     */
    async void load_icons(string context)
    {
        /* Fix sidebar up */
        Gtk.IconTheme? icon_theme = Gtk.IconTheme.get_default();
        Gtk.StyleContext st = this.get_style_context();
        Gtk.TreeIter iter;

        message("loading");

        foreach (var iname in icon_theme.list_icons(context)) {
            try {
                if (iname == null) {
                    continue;
                }
                var info = icon_theme.lookup_icon(iname, 32, 0);
                if (info == null) {
                    continue;
                }

                var pixbuf = yield info.load_symbolic_for_context_async(st, null);
                if (pixbuf == null) {
                    continue;
                }

                icon_model.append(out iter);
                icon_model.set(iter, 0, pixbuf, 1, iname, 2, context, -1);
            } catch (Error e) { }
        }
        this.filter_model.refilter();
        message("done");
    }

    /**
     * Very simple alpha sort
     */
    int sort_sidebar(Gtk.ListBoxRow? left, Gtk.ListBoxRow? right)
    {
        return GLib.strcmp((left as IconContextLabel).category, (right as IconContextLabel).category);
    }

    /**
     * Create a file chooser UI
     */
    void create_file_area()
    {
        Gtk.FileChooserWidget w = new Gtk.FileChooserWidget(Gtk.FileChooserAction.OPEN);
        w.set_select_multiple(false);
        w.set_show_hidden(false);

        /* We need gdk-pixbuf usable files */
        Gtk.FileFilter filter = new Gtk.FileFilter();
        filter.add_pixbuf_formats();
        filter.set_name(_("Image files"));
        w.add_filter(filter);

        /* Also need an Any filter to be a human about it */
        filter = new Gtk.FileFilter();
        filter.add_pattern("*");
        filter.set_name(_("Any file"));
        w.add_filter(filter);

        /* i.e. don't allow weird selections like Google Drive in gvfs and make Budgie hang */
        w.set_local_only(true);

        /* Prefer the users XDG pictures directory by default */
        string? picture_dir = Environment.get_user_special_dir(UserDirectory.PICTURES);
        if (picture_dir != null) {
            w.set_current_folder(picture_dir);
        }

        w.selection_changed.connect(on_file_selection_changed);
        this.stack.add_titled(w, "files", _("Local file"));
        w.show_all();
    }

    /**
     * Handle selections in the file chooser
     */
    void on_file_selection_changed(Gtk.FileChooser? w)
    {
        string? selection = w.get_uri();
        if (selection == null) {
            icon_pick = null;
            button_set_icon.sensitive = false;
            return;
        }
        icon_pick = "" + selection;
        button_set_icon.sensitive = true;
    }

    /**
     * Utility method to modally run the dialog and return a consumable response
     */
    public new string? run()
    {
        int resp = base.run();

        if (resp == Gtk.ResponseType.ACCEPT) {
            return this.icon_pick;
        }

        return null;
    }
} /* End IconChooser */
