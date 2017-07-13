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
 * IconChooser is a very trivial dialog that allows users to dynamically
 * select an icon from the icon theme or from a given file path
 */
public class IconChooser : Gtk.Dialog
{

    Gtk.Stack stack;
    Gtk.StackSwitcher switcher;
    string? icon_pick = null;
    Gtk.Button button_set_icon;

    /**
     * Construct a new modal IconChooser with the given parent
     */
    public IconChooser(Gtk.Window parent)
    {
        Object(transient_for: parent,
               modal: true,
               use_header_bar: 1);

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
        var w = new Gtk.EventBox();
        this.stack.add_titled(w, "icons", _("Icon theme"));
        w.show_all();
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
