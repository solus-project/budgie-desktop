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

/**
 * Default width for an OSD notification
 */
public const int SWITCHER_SIZE= 350;

/**
 * How long before the visible OSD expires, default is 2.5 seconds
 */
public const int SWITCHER_EXPIRE_TIME = 2500;

/**
 * Our name on the session bus. Reserved for Budgie use
 */
public const string SWITCHER_DBUS_NAME        = "org.budgie_desktop.TabSwitcher";

/**
 * Unique object path on OSD_DBUS_NAME
 */
public const string SWITCHER_DBUS_OBJECT_PATH = "/org/budgie_desktop/TabSwitcher";


/**
 * The BudgieOSD provides a very simplistic On Screen Display service, complying with the
 * private GNOME Settings Daemon -> GNOME Shell protocol.
 *
 * In short, all elements of the permanently present window should be able to hide or show
 * depending on the updated ShowOSD message, including support for a progress bar (level),
 * icon, optional label.
 *
 * This OSD is used by gnome-settings-daemon to portray special events, such as brightness/volume
 * changes, physical volume changes (disk eject/mount), etc. This special window should remain
 * above all other windows and be non-interactive, allowing unobtrosive overlay of information
 * even in full screen movies and games.
 *
 * Each request to ShowOSD will reset the expiration timeout for the OSD's current visibility,
 * meaning subsequent requests to the OSD will keep it on screen in a natural fashion, allowing
 * users to "hold down" the volume change buttons, for example.
 */
[GtkTemplate (ui = "/com/solus-project/budgie/daemon/tabswitcher.ui")]
public class Switcher : Gtk.Window
{

    /**
     * Track the primary monitor to show on
     */
    private int primary_monitor;

    /**
     * Construct a new Switcher widget
     */
    public Switcher()
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

        /* Update the primary monitor notion */
        screen.monitors_changed.connect(on_monitors_changed);

        /* Set up size */
        set_default_size(SWITCHER_SIZE, -1);
        realize();

        get_child().show_all();

        /* Get everything into position prior to the first showing */
        on_monitors_changed();
    }

    /**
     * Monitors changed, find out the primary monitor, and schedule move of OSD
     */
    private void on_monitors_changed()
    {
        primary_monitor = screen.get_primary_monitor();
        move_switcher();
    }

    /**
     * Move the OSD into the correct position
     */
    public void move_switcher()
    {
        /* Find the primary monitor bounds */
        Gdk.Screen sc = get_screen();
        Gdk.Rectangle bounds;

        sc.get_monitor_geometry(primary_monitor, out bounds);
        Gtk.Allocation alloc;

        get_child().get_allocation(out alloc);

        /* For now just center it */
        int x = bounds.x + ((bounds.width / 2) - (alloc.width / 2));
        int y = bounds.y + ((int)(bounds.height * 0.85));
        move(x, y);
    }
} /* End class OSD (BudgieOSD) */

/**
 * BudgieOSDManager is responsible for managing the BudgieOSD over d-bus, receiving
 * requests, for example, from budgie-wm
 */
[DBus (name = "org.budgie_desktop.TabSwitcher")]
public class TabSwitcher
{
    private Switcher? switcher_window = null;
    private uint32 expire_timeout = 0;

    [DBus (visible = false)]
    public TabSwitcher()
    {
        switcher_window = new Switcher();
    }

    /**
     * Own the OSD_DBUS_NAME
     */
    [DBus (visible = false)]
    public void setup_dbus()
    {
        Bus.own_name(BusType.SESSION, Budgie.SWITCHER_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, ()=> {}, ()=> { warning("TabSwitcher could not take dbus!"); });
    }

    /**
     * Acquired OSD_DBUS_NAME, register ourselves on the bus
     */
    private void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object(Budgie.SWITCHER_DBUS_OBJECT_PATH, this);
        } catch (Error e) {
            stderr.printf("Error registering TabSwitcher: %s\n", e.message);
        }
    }

    /**
     * Show the OSD on screen with the given parameters:
     * icon: string Icon-name to use
     * label: string Text to display, if any
     * level: int32 Progress-level to display in the OSD
     * monitor: int32 The monitor to display the OSD on (currently ignored)
     */
    public void PassItem(uint32 id)
    {
	message("Got id: %" + uint32.FORMAT + "", id);
    }

    public void ShowSwitcher(uint32 curr_xid)
    {
    	message("Next window: %" + uint32.FORMAT + "", curr_xid);
        this.reset_switcher_expire(SWITCHER_EXPIRE_TIME);
    }

    /**
     * Reset and update the expiration for the OSD timeout
     */
    private void reset_switcher_expire(int timeout_length)
    {
        if (expire_timeout > 0) {
            Source.remove(expire_timeout);
            expire_timeout = 0;
        }
        if (!switcher_window.get_visible()) {
            switcher_window.move_switcher();
        }
        switcher_window.show();
        expire_timeout = Timeout.add(timeout_length, this.switcher_expire);
    }

    /**
     * Expiration timeout was met, so hide the OSD Window
     */
    private bool switcher_expire()
    {
        if (expire_timeout == 0) {
            return false;
        }
        switcher_window.hide();
        expire_timeout = 0;
        return false;
    }
} /* End class OSDManager (BudgieOSDManager) */

} /* End namespace Budgie */
