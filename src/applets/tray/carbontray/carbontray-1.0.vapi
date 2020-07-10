/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2020-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This file's contents largely use xfce4-panel as a reference, which is licensed under the terms of the GNU GPL v2.
 * Additional notes were taken from na-tray, the previous system tray for Budgie, which is part of MATE Desktop 
 * and licensed under the terms of the GNU GPL v2.
 */

namespace Carbon {
    [Compact]
    [CCode (cheader_filename = "tray.h")]
	public class Tray : GLib.Object {
        [CCode (has_construct_function = false, type = "GtkWidget*")]
        public Tray(Gtk.Orientation orientation, int iconSize, int spacing);

        public void add_to_container(Gtk.Container container);

        public void remove_from_container(Gtk.Container container);
        
        public bool register(Gdk.X11.Screen screen);

        public void unregister();

        public void set_spacing(int spacing);
    }
}
