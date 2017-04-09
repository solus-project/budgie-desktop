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
 * Our name on the session bus. Reserved for Budgie use
 */
public const string MENU_DBUS_NAME        = "org.budgie_desktop.MenuManager";

/**
 * Unique object path on OSD_DBUS_NAME
 */
public const string MENU_DBUS_OBJECT_PATH = "/org/budgie_desktop/MenuManager";


/**
 * BudgieMenuManager is responsible for managing the right click menus of
 * the budgie desktop over dbus, so that GTK+ isn't used inside the WM process
 */
[DBus (name = "org.budgie_desktop.MenuManager")]
public class MenuManager
{

    [DBus (visible = false)]
    public MenuManager()
    {
    }

    /**
     * Own the MENU_DBUS_NAME
     */
    [DBus (visible = false)]
    public void setup_dbus()
    {
        Bus.own_name(BusType.SESSION, Budgie.MENU_DBUS_NAME, BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, ()=> {}, ()=> { warning("BudgieMenuManager could not take dbus!"); });
    }

    /**
     * Acquired MENU_DBUS_NAME, register ourselves on the bus
     */
    private void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object(Budgie.MENU_DBUS_OBJECT_PATH, this);
        } catch (Error e) {
            stderr.printf("Error registering BudgieMenuManager: %s\n", e.message);
        }
    }

} /* End class MenuManager (BudgieMenuManager) */

} /* End namespace Budgie */
