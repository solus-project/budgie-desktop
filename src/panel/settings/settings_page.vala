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

public const string SETTINGS_GROUP_APPEARANCE = "appearance";

/**
 * A SettingsRow is used to control the content layout in a SettingsPage
 * to ensure everyone conforms to the page grid
 */
public class SettingsRow : GLib.Object {

    public Gtk.Widget widget { construct set ; public get; }
    public string label { construct set ; public get; }
    public string? description { construct set ; public get; }

    /* Convenience */
    public SettingsRow(Gtk.Widget? widget, string label, string? description = null)
    {
        this.widget = widget;
        this.label = label;
        this.description = description;
    }

} /* End SettingsRow */

/**
 * A settings page is just a helper with some properties and methods to add
 * new setting items easily without buggering about with the internals of
 * GtkGrids
 */
public class SettingsPage : Gtk.Grid {

    /* Allow sorting the header */
    public string group { public set; public get; }

    /* Assign a page */
    public string content_id { public set ; public get; }

    /* The icon we want in the sidebar */
    public string icon_name { public set; public get; }

    /* The title to display in the sidebar */
    public string title { public set ; public get; }

    private int current_row = 0;

    construct {
        border_width = 20;
        margin_end = 24;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.FILL;
        get_style_context().add_class("settings-page");
    }

    /**
     * Add a new row into this SettingsPage, taking ownership of the row
     * content and widgets.
     */
    public void add_row(SettingsRow? row)
    {
        var lab_main = new Gtk.Label(row.label);
        lab_main.halign = Gtk.Align.START;
        lab_main.hexpand = true;

        attach(lab_main, 0, current_row, 1, 1);
        attach(row.widget, 1, current_row, 1, 1);
        row.widget.halign = Gtk.Align.END;
        row.widget.valign = Gtk.Align.CENTER;
        row.widget.vexpand = false;

        lab_main.margin_top = 12;
        row.widget.margin_left = 28;
        row.widget.margin_top = 12;

        ++current_row;

        if (row.description == null) {
            return;
        }

        var desc_lab = new Gtk.Label(row.description);
        desc_lab.halign = Gtk.Align.START;
        desc_lab.margin_end = 40;

        /* Deprecated but we need this to make line wrap actually work */
        desc_lab.set_property("xalign", 0.0);
        desc_lab.set_line_wrap(true);
        desc_lab.set_line_wrap_mode(Pango.WrapMode.WORD);

        desc_lab.get_style_context().add_class(Gtk.STYLE_CLASS_DIM_LABEL);

        attach(desc_lab, 0, current_row, 1, 1);

        ++current_row;
    }

} /* End SettingsPage */

} /* End namespace */
