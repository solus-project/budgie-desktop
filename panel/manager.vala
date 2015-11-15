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
 
using LibUUID;

namespace Arc
{

public static const string DBUS_NAME        = "com.solus_project.arc.Panel";
public static const string DBUS_OBJECT_PATH = "/com/solus_project/arc/Panel";

/**
 * Available slots
 */

[Flags]
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

/**
 * Maximum slots. 4 because that's generally how many sides a rectangle has..
 */
public static const uint MAX_SLOTS         = 4;

/**
 * Root prefix for fixed schema
 */
public static const string ROOT_SCHEMA     = "com.solus-project.arc-panel";

/**
 * Relocatable schema ID for toplevel panels
 */
public static const string TOPLEVEL_SCHEMA = "com.solus-project.arc-panel.panel";

/**
 * Prefix for all relocatable panel settings
 */
public static const string TOPLEVEL_PREFIX = "/com/solus-project/arc-panel/panels";

/**
 * Known panels
 */
public static const string ROOT_KEY_PANELS    = "panels";

/** Panel position */
public static const string PANEL_KEY_POSITION = "location";

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

    HashTable<int,Screen?> screens;
    HashTable<string,Arc.Panel?> panels;

    int primary_monitor = 0;
    Settings settings;
    Peas.Engine engine;
    Peas.ExtensionSet extensions;

    public PanelManager()
    {
        screens = new HashTable<int,Screen?>(direct_hash, direct_equal);
        panels = new HashTable<string,Arc.Panel?>(str_hash, str_equal);
    }

    string create_panel_path(string uuid)
    {
        return "%s/{%s}/".printf(Arc.TOPLEVEL_PREFIX, uuid);
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
        /* Well, off we go to be a panel manager. */
        do_setup();
    }

    /**
     * Initial setup, once we've owned the dbus name
     * i.e. no risk of dying
     */
    void do_setup()
    {
        var scr = Gdk.Screen.get_default();
        primary_monitor = scr.get_primary_monitor();
        scr.monitors_changed.connect(this.on_monitors_changed);

        this.on_monitors_changed();

        engine = Peas.Engine.get_default();
        //engine.add_search_path(module_directory, module_data_directory);
        extensions = new Peas.ExtensionSet(engine, typeof(Arc.Plugin));

        settings = new GLib.Settings(Arc.ROOT_SCHEMA);
        if (!load_panels()) {
            message("Creating default panel layout");
            create_default();
        } else {
            message("Loading existing configuration");
        }
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
     * Load a panel by the given UUID, and optionally configure it
     */
    void load_panel(string uuid, bool configure = false)
    {
        if (panels.contains(uuid)) {
            return;
        }

        string path = this.create_panel_path(uuid);
        PanelPosition position;

        var settings = new GLib.Settings.with_path(Arc.TOPLEVEL_SCHEMA, path);
        Arc.Panel? panel = new Arc.Panel(uuid, settings);
        panels.insert(uuid, panel);

        if (!configure) {
            return;
        }

        position = (PanelPosition)settings.get_enum(Arc.PANEL_KEY_POSITION);
        this.show_panel(uuid, position);
    }

    void show_panel(string uuid, PanelPosition position)
    {
        Arc.Panel? panel = panels.lookup(uuid);
        Screen? scr;

        if (panel == null) {
            warning("Asked to show non-existent panel: %s", uuid);
            return;
        }

        scr = screens.lookup(this.primary_monitor);
        if ((scr.slots & position) != 0) {
            scr.slots |= position;
        }
        this.set_placement(uuid, position);
    }

    /**
     * Enforce panel placement
     */
    void set_placement(string uuid, PanelPosition position)
    {
        Arc.Panel? panel = panels.lookup(uuid);
        string? key = null;
        Arc.Panel? val = null;
        Arc.Panel? conflict = null;

        if (panel == null) {
            warning("Trying to move non-existent panel: %s", uuid);
            return;
        }
        Screen? area = screens.lookup(primary_monitor);

        PanelPosition old = panel.position;

        if (old == position) {
            warning("Attempting to move panel to the same position it's already in");
            return;
        }

        /* Attempt to find a conflicting position */
        var iter = HashTableIter<string,Arc.Panel?>(panels);
        while (iter.next(out key, out val)) {
            if (val.position == position) {
                conflict = val;
                break;
            }
        }

        panel.hide();
        if (conflict != null) {
            conflict.hide();
            conflict.update_geometry(area.area, old);
            conflict.show();
        } else {
            area.slots ^= old;
            area.slots |= position;
            panel.update_geometry(area.area, position);
        }

        /* This does mean re-configuration a couple of times that could
         * be avoided, but it's just to ensure proper functioning..
         */
        this.update_screen();
        panel.show();
    }

    /**
     * Force update geometry for all panels
     */
    void update_screen()
    {
        string? key = null;
        Arc.Panel? val = null;
        Screen? area = screens.lookup(primary_monitor);
        var iter = HashTableIter<string,Arc.Panel?>(panels);
        while (iter.next(out key, out val)) {
            val.update_geometry(area.area, val.position);
        }
    }

    /**
     * Load all known panels
     */
    bool load_panels()
    {
        string[] panels = this.settings.get_strv(Arc.ROOT_KEY_PANELS);
        if (panels.length == 0) {
            return false;
        }

        foreach (string uuid in panels) {
            this.load_panel(uuid, true);
        }

        this.update_screen();
        return true;
    }

    void create_panel()
    {
        if (this.slots_available() < 1) {
            warning("Asked to create panel with no slots available");
            return;
        }

        var position = get_first_position(this.primary_monitor);
        if (position == PanelPosition.NONE) {
            critical("No slots available, this should not happen");
            return;
        }

        var uuid = LibUUID.new(UUIDFlags.LOWER_CASE|UUIDFlags.TIME_SAFE_TYPE);
        load_panel(uuid, false);

        set_panels();
        show_panel(uuid, position);
    }

    /**
     * Update our known panels
     */
    void set_panels()
    {
        unowned Arc.Panel? panel;
        unowned string? key;
        string[]? keys = null;

        var iter = HashTableIter<string,Arc.Panel?>(panels);
        while (iter.next(out key, out panel)) {
            keys += key;
        }

        this.settings.set_strv(Arc.ROOT_KEY_PANELS, keys);
    }

    /**
     * Create new default panel layout
     */
    void create_default()
    {
        /* Eventually we'll do something fancy with defaults, when
         * applet loading lands */
        create_panel();
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
