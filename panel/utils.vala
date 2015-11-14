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

    public enum PanelPosition
    {
        BOTTOM = 0,
        TOP,
        LEFT,
        RIGHT
    }


    public static void set_struts(Gtk.Window? window, PanelPosition position, long panel_size)
    {
        Gdk.Atom atom;
        Gdk.Rectangle primary_monitor_rect;
        long struts[12];
        var screen = window.screen;
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out primary_monitor_rect);
        /*
        strut-left strut-right strut-top strut-bottom
        strut-left-start-y   strut-left-end-y
        strut-right-start-y  strut-right-end-y
        strut-top-start-x    strut-top-end-x
        strut-bottom-start-x strut-bottom-end-x
        */

        if (!window.get_realized()) {
            return;
        }

        // Struts dependent on position
        switch (position) {
            case PanelPosition.TOP:
                struts = { 0, 0, primary_monitor_rect.y+panel_size, 0,
                    0, 0, 0, 0,
                    primary_monitor_rect.x, primary_monitor_rect.x+primary_monitor_rect.width,
                    0, 0
                };
                break;
            case PanelPosition.LEFT:
                struts = { panel_size, 0, 0, 0,
                    primary_monitor_rect.y, primary_monitor_rect.y+primary_monitor_rect.height, 
                    0, 0, 0, 0, 0, 0
                };
                break;
            case PanelPosition.RIGHT:
                struts = { 0, panel_size, 0, 0,
                    0, 0,
                    primary_monitor_rect.y, primary_monitor_rect.y+primary_monitor_rect.height,
                    0, 0, 0, 0
                };
                break;
            case PanelPosition.BOTTOM:
            default:
                struts = { 0, 0, 0, 
                    (screen.get_height()-primary_monitor_rect.height-primary_monitor_rect.y) + panel_size,
                    0, 0, 0, 0, 0, 0, 
                    primary_monitor_rect.x, primary_monitor_rect.x + primary_monitor_rect.width
                };
                break;
        }

        // all relevant WMs support this, Mutter included
        atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
        Gdk.property_change(window.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
    }

/**
 * Alternative to a separator, gives a shadow effect :)
 *
 * @note Until we need otherwise, this is a vertical only widget..
 */
public class VShadowBlock : Gtk.EventBox
{

    public VShadowBlock()
    {
        get_style_context().add_class("shadow-block");
        get_style_context().add_class("vertical");
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }
}

/**
 * Alternative to a separator, gives a shadow effect :)
 *
 * @note Until we need otherwise, this is a vertical only widget..
 */
public class HShadowBlock : Gtk.EventBox
{

    private int size;

    public int required_size {
        public set {
            size = value;
            queue_resize();
        }
        public get {
            return size;
        }
    }

    public HShadowBlock()
    {
        get_style_context().add_class("shadow-block");
        get_style_context().add_class("horizontal");
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }

    public override void get_preferred_height_for_width(int width, out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        min = required_size;
        nat = required_size;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int nat)
    {
        min = required_size;
        nat = required_size;
    }
}

} // End namespace
