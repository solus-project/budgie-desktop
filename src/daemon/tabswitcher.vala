/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2017-2019 taaem <taaem@mailbox.org>
 * Copyright (C) 2017-2019 Budgie Desktop Developers
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
public const int SWITCHER_SIZE = -1;

/**
 * How often it is checked if the meta key is still pressed
 */
public const int SWITCHER_MOD_EXPIRE_TIME = 50;

/**
 * Our name on the session bus. Reserved for Budgie use
 */
public const string SWITCHER_DBUS_NAME = "org.budgie_desktop.TabSwitcher";

/**
 * Unique object path on SWITCHER_DBUS_NAME
 */
public const string SWITCHER_DBUS_OBJECT_PATH = "/org/budgie_desktop/TabSwitcher";

/**
 * A TabSwitcherWidget is used for each icon in the display
 */
public class TabSwitcherWidget : Gtk.Image {

    /**
     * Display title for the window
     */
    public string title;

    /**
     * X11 window ID
     */
    public uint32 xid;

    /**
     * Last "touched" by the user
     */
    public uint32 usertime;

    public unowned Wnck.Window? wnck_window = null;

    /**
     * Construct a new TabSwitcherWidget with the given xid + title
     */
    public TabSwitcherWidget(Wnck.Window? window, DesktopAppInfo? info, uint32 usertime)
    {
        Object();
        string? title = window.get_name();
        this.title = window.has_name() ? title : "";
        this.title = this.title.strip();
        this.wnck_window = window;
        this.xid = (uint32)window.get_xid();
        this.usertime = usertime;

        set_property("margin", 10);

        if (info != null) {
            set_from_gicon(info.get_icon(), Gtk.IconSize.DIALOG);
        } else {
            set_from_pixbuf(wnck_window.get_icon());
        }
        set_pixel_size(48);
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
    }
}

/**
 *
 */
[GtkTemplate (ui = "/com/solus-project/budgie/daemon/tabswitcher.ui")]
public class TabSwitcherWindow : Gtk.Window
{
    [GtkChild]
    private Gtk.FlowBox window_box;

    [GtkChild]
    private Gtk.Label window_title;

    /**
     * Track the primary monitor to show on
     */
    private Gdk.Monitor primary_monitor;

    private HashTable<uint32, TabSwitcherWidget?> xids = null;

    private Budgie.AppSystem? app_system = null;

    /**
     * Make the current selection the active window
     */
    private void on_hide()
    {
        var selection = window_box.get_selected_children();
        Gtk.FlowBoxChild? current = null;
        if (selection != null && selection.length() > 0) {
            current = selection.nth_data(0) as Gtk.FlowBoxChild;
        }

        if (current == null) {
            return;
        }

        /* Get the window, which should be activated and activate that */
        TabSwitcherWidget? tab = current.get_child() as TabSwitcherWidget;
        uint32 time = (uint32)Gdk.X11.get_server_time(Gdk.get_default_root_window() as Gdk.X11.Window);
        tab.wnck_window.activate(time);

        /* Remove all items so if the widget gets shown again it starts from scratch */
        this.stop_switching();
    }

    /* Remove all items, so the hide method doesn't finds any active window and thus just exits */
    public void stop_switching()
    {
        /* Remove all items so if the widget gets shown again it starts from scratch */
        var children = window_box.get_children();
        foreach (var child in children) {
            child.destroy();
        }
        xids.remove_all();
    }

    /**
     * Construct a new TabSwitcherWindow
     */
    public TabSwitcherWindow()
    {
        Object(type: Gtk.WindowType.POPUP, type_hint: Gdk.WindowTypeHint.NOTIFICATION);
        set_position(Gtk.WindowPosition.CENTER_ALWAYS);
        this.xids = new HashTable<uint32, TabSwitcherWidget?>(GLib.direct_hash, GLib.direct_equal);
        this.app_system = new Budgie.AppSystem();

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
        primary_monitor = screen.get_display().get_primary_monitor();
        move_switcher();
    }

    /**
     * Move the SWITCHER into the correct position
     */
    public void move_switcher()
    {
        /* Find the primary monitor bounds */
        Gdk.Rectangle bounds = primary_monitor.get_geometry();
        Gtk.Allocation alloc;

        get_child().get_allocation(out alloc);

        /* For now just center it */
        int x = bounds.x + ((bounds.width / 2) - (alloc.width / 2));
        int y = bounds.y + ((bounds.height / 2) - (alloc.height / 2));
        move(x, y);
    }

    /* Add a single item to the ListBox and the xid to the List */
    public new void add_window(uint32 xid, uint32 usertime)
    {
        if (this.visible == true) {
            return;
        }
        unowned Wnck.Window? window = null;
        window = Wnck.Window.get(xid);
        if (window == null) {
            return;
        }
        var desktop = this.app_system.query_window(window);

        var child = new TabSwitcherWidget(window, desktop, usertime);
        xids.insert(xid, child);

        /* Adjust to a maximum of 8 children per row */
        var n_kids = xids.size();
        if (n_kids < 8) {
            window_box.set_max_children_per_line(n_kids);
        } else {
            window_box.set_max_children_per_line(8);
        }

        window_box.insert(child, -1);
        queue_resize();
        window_box.show_all();
    }

    /* Switch focus to the item with the xid */
    public void focus_item(uint32 xid)
    {
        /* Get the index of the xid it will be the same as the one the widget has */
        TabSwitcherWidget? widget = xids.lookup(xid);
        if (widget == null) {
            return;
        }
        window_title.set_text(widget.title);
        window_box.select_child(widget.get_parent() as Gtk.FlowBoxChild);
    }
} /* End class Switcher (BudgieSwitcher) */

/**
 * TabSwitcher is responsible for managing the BudgieSwitcher over d-bus, receiving
 * requests, for example, from budgie-wm
 */
[DBus (name = "org.budgie_desktop.TabSwitcher")]
public class TabSwitcher : Object
{
    private TabSwitcherWindow? switcher_window = null;
    private uint32 mod_timeout = 0;

    [DBus (visible = false)]
    public TabSwitcher()
    {
        switcher_window = new TabSwitcherWindow();
    }

    /**
     * Own the SWITCHER_DBUS_NAME
     */
    [DBus (visible = false)]
    public void setup_dbus(bool replace)
    {
        var flags = BusNameOwnerFlags.ALLOW_REPLACEMENT;
        if (replace) {
            flags |= BusNameOwnerFlags.REPLACE;
        }
        Bus.own_name(BusType.SESSION, Budgie.SWITCHER_DBUS_NAME, flags,
            on_bus_acquired, ()=> {}, Budgie.DaemonNameLost);
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
        Budgie.setup = true;
    }

    /**
     * Add items to the SWITCHER with parameters:
     * id: uint32 xid of the item
     * title: string title of the window
     */
    public void PassItem(uint32 id, uint32 usertime)
    {
        switcher_window.add_window(id, usertime);
    }
    /**
     * Show the SWITCHER on screen with the given parameters:
     * curr_xid: uint32 xid of the item to select
     */
    public void ShowSwitcher(uint32 curr_xid)
    {
        this.add_mod_key_watcher();

        switcher_window.move_switcher();
        switcher_window.show();
        switcher_window.focus_item(curr_xid);
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
        Gdk.Display.get_default().get_default_seat().get_pointer().get_state(Gdk.get_default_root_window(), null, out modifier);
        if ((modifier & Gdk.ModifierType.MODIFIER_MASK ) == 0 || (modifier & Gdk.ModifierType.MODIFIER_MASK ) == 2 ) {
            switcher_window.hide();
            return false;
        }

        /* restart the timeout */
        return true;
    }

} /* End class TabSwitcher (BudgieSwitcher) */

} /* End namespace Budgie */
