/*
 * This file is part of arc-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Arc {
    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface PopoverManager : GLib.Object
    {
        public abstract void register_popover(Gtk.Widget? widget, Gtk.Popover? popover);
        public abstract void unregister_popover(Gtk.Widget? widget);
    }
    [CCode (cheader_filename = "ArcPlugin.h")]
    public interface Plugin : GLib.Object {
        public abstract Arc.Applet get_panel_widget ();
    }
    [CCode (cheader_filename = "ArcPlugin.h")]
    public class Applet : Gtk.Bin {
        public Applet();

        public virtual void update_popovers(Arc.PopoverManager? manager) { }
    }
}
