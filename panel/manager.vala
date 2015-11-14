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

public static const string DBUS_NAME        = "com.solus_project.arc.Panel";
public static const string DBUS_OBJECT_PATH = "/com/solus_project/arc/Panel";

/**
 * Available slots
 */
public enum PanelPosition {
    NONE        = 1 << 0,
    BOTTOM      = 1 << 1,
    TOP         = 1 << 2,
    LEFT        = 1 << 3,
    RIGHT       = 1 << 4
}

struct Screen {
    PanelPosition slots;
    Gdk.Rectangle area;
}

public static const uint MAX_SLOTS = 4;

[DBus (name = "com.solus_project.arc.Panel")]
public class PanelManagerIface
{

    public string get_version()
    {
        return "1";
    }
}

public class PanelManager
{
    private PanelManagerIface? iface;
    bool setup = false;

    /* We'll fix this later on.. */
    Arc.Panel? panel;

    HashTable<int,Screen?> screens;
    HashTable<string,Arc.Panel?> panels;

    int primary_monitor = 0;

    public PanelManager()
    {
        screens = new HashTable<int,Screen?>(direct_hash, direct_equal);
        panels = new HashTable<string,Arc.Panel?>(str_hash, str_equal);
    }

    /**
     * Discover all possible monitors, and move things accordingly.
     * In future we'll support per-monitor panels, but for now everything
     * must be in one of the edges on the primary monitor
     */
    public void on_monitors_changed()
    {
        var scr = Gdk.Screen.get_default();
        var mon = scr.get_primary_monitor();
        HashTableIter<string,Arc.Panel?> iter;
        unowned string uuid;
        unowned Arc.Panel panel;
        unowned Screen? primary;

        screens.remove_all();

        /* When we eventually get monitor-specific panels we'll find the ones that
         * were left stray and find new homes, or temporarily disable
         * them */
        for (int i = 0; i < scr.get_n_monitors(); i++) {
            Gdk.Rectangle usable_area;
            scr.get_monitor_geometry(i, out usable_area);
            Arc.Screen? screen = Arc.Screen() {
                area = usable_area,
                slots = 0
            };
            screens.insert(i, screen);
        }

        primary = screens.lookup(mon);

        /* Fix all existing panels here */
        iter = HashTableIter<string,Arc.Panel?>(panels);
        while (iter.next(out uuid, out panel)) {
            if (mon != this.primary_monitor) {
                /* Force existing panels to update to new primary display */
                panel.update_geometry(primary.area, panel.position);
            }
            /* Re-take the position */
            primary.slots |= panel.position;
        }
        this.primary_monitor = mon;
    }

    private void on_bus_acquired(DBusConnection conn)
    {
        try {
            iface = new PanelManagerIface();
            conn.register_object(Arc.DBUS_OBJECT_PATH, iface);
        } catch (Error e) {
            stderr.printf("Error registering PanelManager: %s\n", e.message);
            Process.exit(1);
        }
    }

    public void on_name_acquired(DBusConnection conn, string name)
    {
        this.setup = true;
        create_panels();
    }

    /**
     * Find the next available position on the given monitor
     */
    public PanelPosition get_first_position(int monitor)
    {
        if (!screens.contains(monitor)) {
            error("No screen for monitor: %d - This should never happen!", monitor);
            return PanelPosition.NONE;
        }
        Screen? screen = screens.lookup(monitor);

        if ((screen.slots & PanelPosition.BOTTOM) == 0) {
            return PanelPosition.BOTTOM;
        } else if ((screen.slots & PanelPosition.TOP) == 0) {
            return PanelPosition.TOP;
        } else if ((screen.slots & PanelPosition.LEFT) == 0) {
            return PanelPosition.LEFT;
        } else if ((screen.slots & PanelPosition.RIGHT) == 0) {
            return PanelPosition.RIGHT;
        } else {
            return PanelPosition.NONE;
        }
    }

    /**
     * Determine how many slots are available
     */
    public uint slots_available()
    {
        return MAX_SLOTS - panels.size();
    }

    /**
     * Determine how many slots have been used
     */
    public uint slots_used()
    {
        return panels.size();
    }

    /**
     * For now we're creating one hard-coded panel, in future we'll add
     * all the known panels on screen
     */
    void create_panels()
    {
        var scr = Gdk.Screen.get_default();
        primary_monitor = scr.get_primary_monitor();
        scr.monitors_changed.connect(this.on_monitors_changed);

        this.on_monitors_changed();
        Screen? area = screens.lookup(primary_monitor);

        panel = new Arc.Panel();
        /* Demo, need to actually load from gsettings */
        PanelPosition pos = get_first_position(this.primary_monitor);
        panel.update_geometry(area.area, pos);
        panel.show();
    }

    private void on_name_lost(DBusConnection conn, string name)
    {
        if (setup) {
            message("Replaced existing arc-panel");
        } else {
            message("Another panel is already running. Use --replace to replace it");
        }
        Gtk.main_quit();
    }

    public void serve(bool replace = false)
    {
        var flags = BusNameOwnerFlags.ALLOW_REPLACEMENT;
        if (replace) {
            flags |= BusNameOwnerFlags.REPLACE;
        }
        Bus.own_name(BusType.SESSION, Arc.DBUS_NAME, flags,
            on_bus_acquired, on_name_acquired, on_name_lost);
    }
}

} /* End namespace */
