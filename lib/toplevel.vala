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

namespace Arc
{

public abstract class Toplevel : Gtk.Window
{

    /**
     * Length of our shadow component, to enable Raven blending
     */
    public int shadow_width { public set ; public get; }

    /**
     * Depth of our shadow component, to enable Raven blending
     */
    public int shadow_depth { public set ; public get; default = 5; }

    /**
     * Our required size (height or width dependening on orientation
     */
    public int intended_size { public set ; public get; }

    public bool shadow_visible { public set ; public get; }

    /**
     * Unique identifier for this panel
     */
    public string uuid { public set ; public get; }

    public Arc.PanelPosition position { public set; public get; default = Arc.PanelPosition.BOTTOM; }

    public virtual void reset_shadow() { }

    public abstract GLib.List<Arc.AppletInfo?> get_applets();
    public signal void applet_added(Arc.AppletInfo? info);
    public signal void applet_removed(Arc.AppletInfo? info);

    public signal void applets_changed();

    public abstract bool can_move_applet_left(Arc.AppletInfo? info);
    public abstract bool can_move_applet_right(Arc.AppletInfo? info);

    public abstract void move_applet_left(Arc.AppletInfo? info);
    public abstract void move_applet_right(Arc.AppletInfo? info);

    public abstract void add_new_applet(string id);
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

[Flags]
public enum PanelPosition {
    NONE        = 1 << 0,
    BOTTOM      = 1 << 1,
    TOP         = 1 << 2,
    LEFT        = 1 << 3,
    RIGHT       = 1 << 4
}

[Flags]
public enum AppletPackType {
    START       = 1 << 0,
    END         = 1 << 2
}

[Flags]
public enum AppletAlignment {
    START       = 1 << 0,
    CENTER      = 1 << 1,
    END         = 1 << 2
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
