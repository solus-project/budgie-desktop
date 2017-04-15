/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2017 taaem <taaem@mailbox.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

/**
 * Default width for an Switcher notification
 */
public const int SWITCHER_SIZE= 350;

/**
 * How often it is checked if the meta key is still pressed
 */
public const int SWITCHER_MOD_EXPIRE_TIME = 50;

/**
 * Our name on the session bus. Reserved for Budgie use
 */
public const string SWITCHER_DBUS_NAME        = "org.budgie_desktop.TabSwitcher";

/**
 * Unique object path on SWITCHER_DBUS_NAME
 */
public const string SWITCHER_DBUS_OBJECT_PATH = "/org/budgie_desktop/TabSwitcher";


/**
 *
 */
[GtkTemplate (ui = "/com/solus-project/budgie/daemon/tabswitcher.ui")]
public class Switcher : Gtk.Window
{
    [GtkChild]
    private Gtk.ListBox box;

    /**
     * Track the primary monitor to show on
     */
    private int primary_monitor;

    /**
     * Keep a list of the available windows
     */
    private List<uint32> xids;

    /**
     * Make the current selection the active window
     */
    private void on_hide()
    {
        var current = box.get_selected_row();
        if(current == null){
            return;
        }
        int index = 0;
        while(index <= xids.length()) {
            if(current == box.get_row_at_index(index)) {
                break;
            }
            index++;
        }
        /* Get the window, which should be activated and activate that */
        var active_window = Wnck.Window.get(xids.nth_data(index));
        uint32 time = (uint32)Gdk.x11_get_server_time(Gdk.get_default_root_window());
        active_window.activate(time);

        /* Remove all items so if the widget gets shown again it starts from scratch */
        var children = box.get_children();
        foreach (var child in children) {
            child.destroy();
        }

        xids = null;
    }

    /* Remove all items, so the hide method doesn't finds any active window and thus just exits */
    public void stop_switching()
    {
        /* Remove all items so if the widget gets shown again it starts from scratch */
        var children = box.get_children();
        foreach (var child in children) {
            child.destroy();
        }

        xids = null;
    }

    /**
     * Construct a new Switcher widget
     */
    public Switcher()
    {
        Object(type: Gtk.WindowType.POPUP, type_hint: Gdk.WindowTypeHint.NOTIFICATION);

        this.hide.connect(this.on_hide);
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

        xids = new List<uint32> ();

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
     * Move the SWITCHER into the correct position
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
        int y = bounds.y + ((int)(bounds.height * 0.5));
        move(x, y);
    }

    /* Add a single item to the ListBox and the xid to the List */
    public void add(uint32 xid, string title)
    {
        if(this.visible == true) {
            return;
        }
        if(xids == null) {
            xids = new List<uint32> ();
        }
        xids.append(xid);
        Gtk.Label child = new Gtk.Label(null);
        child.set_markup(title);
        child.set_margin_bottom(10);
        child.set_margin_top(10);
        box.insert(child, -1);
        box.show_all();
    }

    /* Switch focus to the item with the xid */
    public void focus_item(uint32 xid)
    {
        /* Get the index of the xid it will be the same as the one the widget has */
        int index = 0;
        while(index <= xids.length()) {
            if(xids.nth_data(index) == xid) {
                break;
            }
            index++;
        }

        var new_row = box.get_row_at_index(index);
        box.select_row(new_row);
    }
} /* End class Switcher (BudgieSwitcher) */

/**
 * TabSwitcher is responsible for managing the BudgieSwitcher over d-bus, receiving
 * requests, for example, from budgie-wm
 */
[DBus (name = "org.budgie_desktop.TabSwitcher")]
public class TabSwitcher
{
    private Switcher? switcher_window = null;
    private uint32 mod_timeout = 0;

    [DBus (visible = false)]
    public TabSwitcher()
    {
        switcher_window = new Switcher();
    }

    /**
     * Own the SWITCHER_DBUS_NAME
     */
    [DBus (visible = false)]
    public void setup_dbus()
    {
        Bus.own_name(BusType.SESSION, Budgie.SWITCHER_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, ()=> {}, ()=> { warning("TabSwitcher could not take dbus!"); });
    }

    /**
     * Acquired SWITCHER_DBUS_NAME, register ourselves on the bus
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
     * Add items to the SWITCHER with parameters:
     * id: uint32 xid of the item
     * title: string title of the window
     */
    public void PassItem(uint32 id, string title)
    {
        switcher_window.add(id, title);
    }
    /**
     * Show the SWITCHER on screen with the given parameters:
     * curr_xid: uint32 xid of the item to select
     */
    public void ShowSwitcher(uint32 curr_xid)
    {
        switcher_window.focus_item(curr_xid);
        this.add_mod_key_watcher();

        switcher_window.show();
    }

    public void StopSwitcher()
    {
        switcher_window.stop_switching();
    }

    private void add_mod_key_watcher()
    {
        if(mod_timeout != 0){
            Source.remove(mod_timeout);
            mod_timeout = 0;
        }
        mod_timeout = Timeout.add(SWITCHER_MOD_EXPIRE_TIME, (GLib.SourceFunc)this.check_mod_key);
    }

    private bool check_mod_key()
    {
        mod_timeout = 0;
        Gdk.ModifierType modifier;
        Gdk.Display.get_default().get_device_manager().get_client_pointer().get_state(Gdk.get_default_root_window(), null, out modifier);
        // Check if alt or windows key is pressed 80 and 24 are the codes, getting these programmatically didn't worked out so this works
        if((int)modifier != 80 && (int)modifier != 24 && (int)modifier != 81 && (int)modifier != 25)
        {
            /* All done now hide and stop the timer */
            switcher_window.hide();
            return false;
        }
        /* restart the timeout */
        return true;
    }

} /* End class TabSwitcher (BudgieSwitcher) */

} /* End namespace Budgie */
