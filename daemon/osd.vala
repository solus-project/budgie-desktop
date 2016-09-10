/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public static const int OSD_SIZE = 400;

public class OSD : Gtk.Window
{
    public OSD()
    {
        Object(type: Gtk.WindowType.POPUP, type_hint: Gdk.WindowTypeHint.NOTIFICATION);
        /* Skip everything, appear above all else, everywhere. */
        resizable = false;
        skip_pager_hint = true;
        skip_taskbar_hint = true;
        set_decorated(false);
        set_keep_above(true);
        stick();

        /* Set up an RGBA map for transparency styling */
        Gdk.Visual? vis = screen.get_rgba_visual();
        if (vis != null) {
            this.set_visual(vis);
        }

        /* Set up size and style context */
        set_default_size(OSD_SIZE, -1);
        get_style_context().add_class("budgie-osd");

        /* Temporary, we'll add proper widgets soon.. */
        Gtk.Box child = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(child);
        realize();
        move_osd();

        /* Temp! */
        show_all();
    }

    /**
     * Move the OSD into the correct position
     */
    private void move_osd()
    {
        /* Find the primary monitor bounds */
        Gdk.Screen sc = get_screen();
        int monitor = sc.get_primary_monitor();
        Gdk.Rectangle bounds;

        sc.get_monitor_geometry(monitor, out bounds);
        Gtk.Allocation alloc;

        get_allocation(out alloc);

        /* For now just center it */
        int x = bounds.x + ((bounds.width / 2) - (alloc.width / 2));
        int y = bounds.y + ((bounds.height / 2) - (alloc.height / 2));
        move(x, y);
    }
} /* End class OSD (BudgieOSD) */

} /* End namespace Budgie */
