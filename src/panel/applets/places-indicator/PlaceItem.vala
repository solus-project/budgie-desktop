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

public class PlaceItem : ListItem
{
    public PlaceItem(GLib.File file, string class)
    {
        item_class = class;

        // Get and set the appropriate icon
        try {
            GLib.FileInfo info = file.query_info("standard::symbolic-icon", GLib.FileQueryInfoFlags.NONE, null);
            set_button(file.get_basename(), get_icon(info.get_symbolic_icon()));
        } catch (GLib.Error e) {
            set_button(file.get_basename(), get_icon(null));
            warning(e.message);
        }

        name_button.set_tooltip_text(_("Open \"%s\"".printf(file.get_basename())));

        name_button.clicked.connect(()=> {
            open_directory(file.get_uri());
        });
    }
}