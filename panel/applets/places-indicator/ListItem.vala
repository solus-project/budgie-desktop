/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Solus Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ListItem : Gtk.Box
{
    protected string item_class;
    protected string category_name;
    protected string item_location;
    protected Gtk.ToolButton name_button;

    construct
    {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 0;

        name_button = new Gtk.ToolButton(null, null);
        name_button.get_child().get_style_context().add_class("name-button");
        name_button.set_can_focus(false);
        name_button.set_tooltip_text(_("Open location"));

        // Open the location in the file manager
        name_button.clicked.connect(()=> {
            try {
                Gtk.show_uri(Gdk.Screen.get_default(), item_location, Gdk.CURRENT_TIME);
            } catch (GLib.Error e) {
                message(e.message);
            }
        });

        pack_start(name_button, true, true, 0);
    }

    /*
     * Add content to our name button
     */
    protected void set_button(string label, Gtk.Image image)
    {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        image.margin_end = 5;
        box.pack_start(image, false, false, 0);

        Gtk.Label label_w = new Gtk.Label(label);
        label_w.set_max_width_chars(25);
        label_w.set_ellipsize(Pango.EllipsizeMode.END);
        label_w.set_halign(Gtk.Align.START);
        box.pack_start(label_w, true, true, 0);

        name_button.set_label_widget(box);
    }

    /*
     * Retrieves the file icon.
     * Returns an appropriate substitute if the file does not provide an icon
     */
    protected Gtk.Image get_icon(GLib.Icon? icon)
    {
        if (icon != null) {
            return new Gtk.Image.from_gicon(icon, Gtk.IconSize.MENU);
        }

        string icon_name;

        switch (item_class) {
            case "device":
                icon_name = "drive-harddisk-symbolic";
                break;
            case "network":
                icon_name = "folder-remote-symbolic";
                break;
            case "place":
            default:
                icon_name = "folder-symbolic";
                break;
        }

        return new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.MENU);
    }

    /*
     * Retrieves the category name
     * Used for list headers
     */
    public string get_item_category() {
        return category_name;
    }
}