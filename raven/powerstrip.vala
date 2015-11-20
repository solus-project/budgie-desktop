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

[DBus (name="org.freedesktop.DisplayManager.Seat")]
public interface DMSeat : Object
{
    public abstract void lock() throws IOError;
}

public class PowerStrip : Gtk.EventBox
{

    private DMSeat? proxy = null;

    public PowerStrip(Arc.Raven? raven)
    {
        Gtk.Box? bottom = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);

        margin_top = 10;
        get_style_context().add_class("header-widget");
        bottom.halign = Gtk.Align.CENTER;
        bottom.margin_top = 5;
        bottom.margin_bottom = 5;
        add(bottom);

        get_style_context().add_class("primary-control");

        var btn = new Gtk.Button.from_icon_name("preferences-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            try {
                raven.set_expanded(false);
                Process.spawn_command_line_async("gnome-control-center");
            } catch (Error e) {
                message("Error invoking gnome-control-center: %s", e.message);
            }
        });
        btn.halign = Gtk.Align.START;
        btn.get_style_context().add_class("flat");
        bottom.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("system-lock-screen-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            raven.set_expanded(false);
            lock_screen();
        });
        var lock_btn = btn;
        btn.halign = Gtk.Align.START;
        btn.get_style_context().add_class("flat");
        bottom.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            try {
                raven.set_expanded(false);
                /* TODO: Swap this out for gnome-session stuff */
                Process.spawn_command_line_async("budgie-session-dialog");
            } catch (Error e) {
                message("Error invoking end session dialog: %s", e.message);
            }
        });
        btn.halign = Gtk.Align.START;
        btn.get_style_context().add_class("flat");
        bottom.pack_start(btn, false, false, 0);

        var path = Environment.get_variable("XDG_SEAT_PATH");
        if (path == null) {
            lock_btn.no_show_all = true;
            lock_btn.hide();
        }
    }

    void lock_screen()
    {
        var path = Environment.get_variable("XDG_SEAT_PATH");

        try {
            if (proxy == null) {
                proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.DisplayManager", path);
            }
            proxy.lock();
        } catch (Error e) {
            warning(e.message);
            proxy = null;
            return;
        }
    }
}

} /* End namespace */
