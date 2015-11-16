/*
 * This file is part of arc-desktop
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

public class Raven : Gtk.Window
{

    public Raven()
    {
        Object(type_hint: Gdk.WindowTypeHint.UTILITY, gravity : Gdk.Gravity.EAST);
        get_style_context().add_class("arc-container");

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        resizable = true;
        skip_taskbar_hint = true;
        skip_pager_hint = true;
        set_keep_above(true);
        set_decorated(false);
    }

    public void update_geometry(Gdk.Rectangle rect, Arc.Toplevel? top, Arc.Toplevel? bottom)
    {
        /* TODO: Implement */
    }
}

} /* End namespace */
