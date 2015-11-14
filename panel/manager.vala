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

    public PanelManager()
    {
        /* TODO: Add init code */
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

    public void on_name_acquired(DBusConnection conn, string name) {
        this.setup = true;
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
