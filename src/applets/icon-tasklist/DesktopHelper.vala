/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2018 Budgie Desktop Developers
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
    public static GLib.Settings settings;
    public static Wnck.Screen screen;
    public static Gtk.Box icon_layout;
    public static bool lock_icons = false;
    public static Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;
    public static int panel_size = 40;
    public static int icon_size = 32;
    public static Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;

    public const Gtk.TargetEntry[] targets = {
        { "application/x-icon-tasklist-launcher-id", 0, 0 },
        { "text/uri-list", 0, 0 },
        { "application/x-desktop", 0, 0 }
    };

    public static void update_pinned()
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

        settings.set_strv("pinned-launchers", buttons);
    }

    public static GLib.List<unowned Wnck.Window> get_stacked_for_classgroup(Wnck.ClassGroup class_group)
    {
        GLib.List<unowned Wnck.Window> list = new GLib.List<unowned Wnck.Window>();
        screen.get_windows_stacked().foreach((window) => {
            if (window.get_class_group() == class_group && !window.is_skip_tasklist()) {
                if (window.get_workspace() == get_active_workspace()) {
                    list.append(window);
                }
            }
        });

        return list.copy();
    }

    public static Wnck.Window get_active_window() {
        return screen.get_active_window();
    }

    public static Wnck.Workspace get_active_workspace() {
        return screen.get_active_workspace();
    }
}
