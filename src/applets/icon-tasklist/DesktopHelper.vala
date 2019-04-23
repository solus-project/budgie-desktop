/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
 
/**
 * Trivial helper for IconTasklist - i.e. desktop lookups
 */
public class DesktopHelper : GLib.Object
{
    private GLib.Settings? settings = null;
    private Wnck.Screen? screen = null;
    private Gtk.Box? icon_layout = null;

    /* Panel specifics */
    public int panel_size = 40;
    public int icon_size = 32;
    public Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;
    public Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;

    /* Preferences */
    public bool lock_icons = false;

    /**
     * Handle initial bootstrap of the desktop helper
     */
    public DesktopHelper(GLib.Settings? settings, Gtk.Box? icon_layout)
    {
        /* Stash privates */
        this.settings = settings;
        this.icon_layout = icon_layout;

        /* Stash lifetime reference to screen */
        this.screen = Wnck.Screen.get_default();
    }

    public const Gtk.TargetEntry[] targets = {
        { "application/x-icon-tasklist-launcher-id", 0, 0 },
        { "text/uri-list", 0, 0 },
        { "application/x-desktop", 0, 0 }
    };

    /**
     * Using our icon_layout, update the per-instance "pinned-launchers" key
     * Keeping with pinned internally for compatibility.
     */
    public void update_pinned()
    {
        string[] buttons = {};
        foreach (Gtk.Widget widget in icon_layout.get_children()) {
            IconButton button = (widget as ButtonWrapper).button;
            if (!button.is_pinned()) {
                continue;
            }
            if (button.get_appinfo() == null) {
                continue;
            }
            string id = button.get_appinfo().get_id();
            if (id in buttons) {
                continue;
            }
            buttons += id;
        }

        settings.set_strv("pinned-launchers", buttons); // Keeping with pinned- internally for compatibility.
    }

    /**
     * Grab the list of windows stacked for the given class_group
     */
    public GLib.List<unowned Wnck.Window> get_stacked_for_classgroup(Wnck.ClassGroup class_group)
    {
        GLib.List<unowned Wnck.Window> list = new GLib.List<unowned Wnck.Window>();
        screen.get_windows_stacked().foreach((window) => {
            if (window.get_class_group() == class_group && !window.is_skip_tasklist()) {
                var workspace = window.get_workspace();
                if (workspace == null) {
                    return;
                }
                if (workspace == get_active_workspace()) {
                    list.append(window);
                }
            }
        });

        return list.copy();
    }

    /**
     * Return the currently active window
     */
    public Wnck.Window get_active_window() {
        return screen.get_active_window();
    }

    /**
     * Return the currently active workspace
     */
    public Wnck.Workspace get_active_workspace() {
        return screen.get_active_workspace();
    }
}
