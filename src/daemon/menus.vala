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

    private Gtk.Menu? desktop_menu = null;

    [DBus (visible = false)]
    public MenuManager()
    {
        init_desktop_menu();
    }

    /**
     * Construct the root level desktop menu (right click on wallpaper
     */
    private void init_desktop_menu()
    {
        desktop_menu = new Gtk.Menu();
        desktop_menu.show();
        var item = new Gtk.MenuItem.with_label(_("Change background"));
        item.activate.connect(background_activate);
        item.show();
        desktop_menu.append(item);

        var sep = new Gtk.SeparatorMenuItem();
        sep.show();
        desktop_menu.append(sep);

        item = new Gtk.MenuItem.with_label(_("Settings"));
        item.activate.connect(settings_activate);
        item.show();
        desktop_menu.append(item);
    }

    /**
     * Launch a .desktop name in a fail safe fashion
     */
    private void launch_desktop_name(string desktop_name)
    {
        try {
            var info = new DesktopAppInfo(desktop_name);
            if (info != null) {
                info.launch(null, null);
            }
        } catch (Error e) {
            warning("Unable to launch %s: %s", desktop_name, e.message);
        }
    }

    /**
     * Launch the Background (wallpaper) settings
     */
    private void background_activate()
    {
        launch_desktop_name("gnome-background-panel.desktop");
    }

    /**
     * Launch main settings (gnome control center)
     */
    private void settings_activate()
    {
        launch_desktop_name("gnome-control-center.desktop");
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

    /**
     * We've been asked to display the root menu for the desktop itself,
     * which contains actions for launching the settings, etc.
     */
    public void ShowDesktopMenu(uint button, uint32 timestamp)
    {
        Idle.add(()=> {
            desktop_menu.popup(null, null, null, button, timestamp);
            return false;
        });
    }

} /* End class MenuManager (BudgieMenuManager) */

} /* End namespace Budgie */
