/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

/* Currently unused by us */
[DBus (name = "org.gnome.SessionManager.Inhibitor")]
public interface Inhibitor : GLib.Object
{
    public abstract string GetAppId() throws Error;
    public abstract string GetReason() throws Error;
}

public enum DialogType {
    LOGOUT = 0,
    SHUTDOWN = 1,
    RESTART = 2,
    UPDATE_RESTART = 3
}

[GtkTemplate (ui="/com/solus-project/arc/endsession/endsession.ui")]
[DBus (name = "com.solus_project.Session.EndSessionDialog")]
public class EndSessionDialog : Gtk.Window
{

    public signal void ConfirmedLogout();
    public signal void ConfirmedReboot();
    public signal void ConfirmedShutdown();
    public signal void Canceled();
    public signal void Closed();

    [GtkCallback]
    [DBus (visible=false)]
    void cancel_clicked()
    {
        Canceled();
        Closed();
        hide();
    }

    [GtkCallback]
    [DBus (visible=false)]
    void logout_clicked()
    {
        Closed();
        ConfirmedLogout();
    }

    [GtkCallback]
    [DBus (visible=false)]
    void restart_clicked()
    {
        Closed();
        ConfirmedReboot();
    }

    [GtkCallback]
    [DBus (visible=false)]
    void shutdown_clicked()
    {
        Closed();
        ConfirmedShutdown();
    }

    private bool showing = false;

    [DBus (visible = false)]
    void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object("/com/solus_project/Session/EndSessionDialog", this);
        } catch (Error e) {
            warning("Cannot register EndSessionDialog");
        }
    }

    [DBus (visible = false)]
    public EndSessionDialog()
    {
        Bus.own_name(BusType.SESSION, "com.solus_project.Session.EndSessionDialog", BusNameOwnerFlags.NONE,
            on_bus_acquired, null, null);
        set_keep_above(true);

        Gdk.Visual? visual = screen.get_rgba_visual();
        if (visual != null) {
            this.set_visual(visual);
        }

        var header = new Gtk.EventBox();
        set_titlebar(header);
        header.get_style_context().remove_class("titlebar");

        delete_event.connect(()=> {
            this.cancel_clicked();
            return Gdk.EVENT_STOP;
        });
    }

    public void Open(uint type, uint timestamp, uint open_length, ObjectPath[] inhibiters)
    {
        /* Right now we ignore type, time and inhibitors. Shush */
        this.present();
    }

    public void Close()
    {
        hide();
        Closed();
    }
}

} /* End namespace */
