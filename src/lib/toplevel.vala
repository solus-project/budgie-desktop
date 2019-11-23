/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie
{

public enum Struts
{
    LEFT,
    RIGHT,
    TOP,
    BOTTOM,
    LEFT_START,
    LEFT_END,
    RIGHT_START,
    RIGHT_END,
    TOP_START,
    TOP_END,
    BOTTOM_START,
    BOTTOM_END
}

public abstract class Toplevel : Gtk.Window
{

    /**
     * Depth of our shadow component, to enable Raven blending
     */
    public int shadow_depth { public set ; public get; default = 5; }

    /**
     * Our required size (height or width dependening on orientation
     */
    public int intended_size { public set ; public get; }

    public bool shadow_visible { public set ; public get; }
    public bool theme_regions { public set; public get; }
    public bool dock_mode { public set; public get; default = false; }
    public bool intersected { public set; public get; default = false; }

    /**
     * Unique identifier for this panel
     */
    public string uuid { public set ; public get; }

    public Budgie.PanelPosition position { public set; public get; default = Budgie.PanelPosition.BOTTOM; }
    public Budgie.PanelTransparency transparency { public set; public get; default = Budgie.PanelTransparency.NONE; }
    public Budgie.AutohidePolicy autohide { public set; public get; default = Budgie.AutohidePolicy.NONE; }


    public abstract GLib.List<Budgie.AppletInfo?> get_applets();
    public signal void applet_added(Budgie.AppletInfo? info);
    public signal void applet_removed(string uuid);

    public signal void applets_changed();

    public abstract bool can_move_applet_left(Budgie.AppletInfo? info);
    public abstract bool can_move_applet_right(Budgie.AppletInfo? info);

    public abstract void move_applet_left(Budgie.AppletInfo? info);
    public abstract void move_applet_right(Budgie.AppletInfo? info);

    public abstract void add_new_applet(string id);
    public abstract void remove_applet(Budgie.AppletInfo? info);
}

public static void set_struts(Gtk.Window? window, PanelPosition position, long panel_size)
{
    Gdk.Atom atom;
    long struts[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var screen = window.screen;
    Gdk.Monitor mon = screen.get_display().get_primary_monitor();
    Gdk.Rectangle primary_monitor_rect = mon.get_geometry();
    int scale = window.get_scale_factor();
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

    message("rect_x %d", primary_monitor_rect.x);
    message("rect_y %d", primary_monitor_rect.y);
    message("width %d", primary_monitor_rect.width);
    message("height %d", primary_monitor_rect.height);
    message("size %d", (int)panel_size);

    //left, right, top, bottom, left_start_y, left_end_y, right_start_y, right_end_y, top_start_x, top_end_x, ottom_start_x, bootom_end_x
    //0     1       2    3       4             5           6              7            8            9         10             11              s

    // Struts dependent on position


    switch (position) {
        case PanelPosition.TOP:
            struts[Struts.TOP] = (panel_size + primary_monitor_rect.y) * scale;
            struts[Struts.TOP_START] = primary_monitor_rect.x * scale;
            struts[Struts.TOP_END] = (primary_monitor_rect.x + primary_monitor_rect.width) * scale - 1;

            //  struts [Struts.TOP] = (monitor_geo.y + VisibleDockHeight) * window_scale_factor;
			//	struts [Struts.TOP_START] = monitor_geo.x * window_scale_factor;
			//	struts [Struts.TOP_END] = (monitor_geo.x + monitor_geo.width) * window_scale_factor - 1;
            break;
        case PanelPosition.LEFT:
            panel_size += 5;
            struts[Struts.LEFT] = (primary_monitor_rect.x + panel_size) * scale;
            struts[Struts.LEFT_START] = primary_monitor_rect.y * scale;
            struts[Struts.LEFT_END] = (primary_monitor_rect.y + primary_monitor_rect.height) * scale - 1;

            //struts [Struts.LEFT] = (monitor_geo.x + VisibleDockWidth) * window_scale_factor;
            //struts [Struts.LEFT_START] = monitor_geo.y * window_scale_factor;
            //struts [Struts.LEFT_END] = (monitor_geo.y + monitor_geo.height) * window_scale_factor - 1;
            break;
        case PanelPosition.RIGHT:
            panel_size += 5;
            struts[Struts.RIGHT] = (screen.get_width() + panel_size) - (primary_monitor_rect.x + primary_monitor_rect.width) * scale;
            struts[Struts.RIGHT_START] = primary_monitor_rect.y * scale;
            struts[Struts.RIGHT_END] = (primary_monitor_rect.y + primary_monitor_rect.height) * scale - 1;
            //struts [Struts.RIGHT] = (VisibleDockWidth + controller.window.get_screen ().get_width () - monitor_geo.x - monitor_geo.width) * window_scale_factor;
            //struts [Struts.RIGHT_START] = monitor_geo.y * window_scale_factor;
            //struts [Struts.RIGHT_END] = (monitor_geo.y + monitor_geo.height) * window_scale_factor - 1;

            break;
        case PanelPosition.BOTTOM:
        default:
            struts[Struts.BOTTOM] = (panel_size + screen.get_height() - primary_monitor_rect.y - primary_monitor_rect.height) * scale;
            struts[Struts.BOTTOM_START] = primary_monitor_rect.x * scale;
            struts[Struts.BOTTOM_END] = (primary_monitor_rect.x + primary_monitor_rect.width) * scale - 1;

            //struts [Struts.BOTTOM] = (VisibleDockHeight + controller.window.get_screen ().get_height () - monitor_geo.y - monitor_geo.height) * window_scale_factor;
            //struts [Struts.BOTTOM_START] = monitor_geo.x * window_scale_factor;
            //struts [Struts.BOTTOM_END] = (monitor_geo.x + monitor_geo.width) * window_scale_factor - 1;
            break;
    }

    atom = Gdk.Atom.intern("_NET_WM_STRUT", false);
    Gdk.property_change(window.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
        32, Gdk.PropMode.REPLACE, (uint8[])struts, 4);

    atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
    Gdk.property_change(window.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
        32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
}

public static void unset_struts(Gtk.Window? window)
{
    Gdk.Atom atom;
    long struts[12];

    if (!window.get_realized()) {
        return;
    }

    struts = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    atom = Gdk.Atom.intern("_NET_WM_STRUT", false);
    Gdk.property_change(window.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
        32, Gdk.PropMode.REPLACE, (uint8[])struts, 4);

    atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
    Gdk.property_change(window.get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
        32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
}

[Flags]
public enum PanelTransparency {
    NONE        = 1 << 0,
    DYNAMIC     = 1 << 1,
    ALWAYS      = 1 << 2
}

[Flags]
public enum AutohidePolicy {
    NONE        = 1 << 0,
    AUTOMATIC   = 1 << 1,
    INTELLIGENT = 1 << 2
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

} /* End namespace */

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */
