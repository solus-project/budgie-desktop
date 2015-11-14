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

    public static string position_class_name(PanelPosition position)
    {
        switch (position) {
            case PanelPosition.TOP:
                return "top";
            case PanelPosition.BOTTOM:
                return "bottom";
            case PanelPosition.LEFT:
                return "left";
            case PanelPosition.RIGHT:
                return "right";
            default:
                return "";
        }
    }

/**
 * Alternative to a separator, gives a shadow effect :)
 */
public class ShadowBlock : Gtk.EventBox
{

    private int size;
    private PanelPosition pos;
    private bool horizontal = false;

    public PanelPosition position {
        public set {
            var old = pos;
            pos = value;
            update_position(old);
        }
        public get {
            return pos;
        }
    }

    public int required_size {
        public set {
            size = value;
            queue_resize();
        }
        public get {
            return size;
        }
    }

    void update_position(PanelPosition? old)
    {
        string? rm = Arc.position_class_name(old);
        string? add = Arc.position_class_name(pos);
        var style = get_style_context();

        if (pos == PanelPosition.TOP || pos == PanelPosition.BOTTOM) {
            horizontal = true;
        } else {
            horizontal = false;
        }

        style.remove_class(rm);
        style.add_class(add);
        queue_resize();
    }

    public ShadowBlock(PanelPosition position)
    {
        get_style_context().add_class("shadow-block");
        get_style_context().remove_class("background");
        this.position = position;
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        if (horizontal) {
            min = 5;
            nat = 5;
            return;
        };
        min = nat = required_size;
    }

    public override void get_preferred_height_for_width(int width, out int min, out int nat)
    {
        if (horizontal) {
            min = 5;
            nat = 5;
            return;
        }
        min = nat = required_size;
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        if (horizontal) {
            min = required_size;
            nat = required_size;
            return;
        }
        min = nat = 5;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int nat)
    {
        if (horizontal) {
            min = required_size;
            nat = required_size;
            return;
        }
        min = nat = 5;
    }
}

} // End namespace
