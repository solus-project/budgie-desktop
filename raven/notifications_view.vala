/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * Copyright 2014 Josh Klar <j@iv597.com> (original Budgie work, prior to Arc)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

public enum NotificationCloseReason {
    EXPIRED = 1,    /** The notification expired. */
    DISMISSED = 2, /** The notification was dismissed by the user. */
    CLOSED = 3,     /** The notification was closed by a call to CloseNotification. */
    UNDEFINED = 4  /** Undefined/reserved reasons. */
}

[DBus (name = "org.freedesktop.Notifications")]
public class NotificationsView : Gtk.Box
{

    string[] caps = {
        "body", "body-markup", "actions", "action-icons"
    };

    public async string[] get_capabilities()
    {
        return caps;
    }

    public async void CloseNotification(uint32 id) {
        /* TODO: Implement */
        yield;
    }

    uint32 notif_id = 0;

    public async uint32 Notify(string app_name, uint32 replaces_id, string app_icon,
                           string summary, string body, string[] actions,
                           HashTable<string, Variant> hints, int32 expire_timeout)
    {
        ++notif_id;
        return notif_id;
    }
    
    /* Let the client know the notification was closed */
    public signal void NotificationClosed(uint32 id, uint32 reason);
    public signal void ActionInvoked(uint32 id, string action_key);

    public void GetServerInformation(out string name, out string vendor,
                                      out string version, out string spec_version) 
    {
        name = "Raven";
        vendor = "Solus Project";
        version = "0.0.3";
        spec_version = "1";
    }

    [DBus (visible = false)]
    public NotificationsView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        var img = new Gtk.Image.from_icon_name("list-remove-all-symbolic", Gtk.IconSize.MENU);
        img.margin_top = 4;
        img.margin_bottom = 4;

        var header = new HeaderWidget("No new notifications", "notification-alert-symbolic", false, null, img);
        header.margin_top = 6;

        pack_start(header, false, false, 0);

        show_all();

        serve_dbus();
    }

    [DBus (visible = false)]
    void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object("/org/freedesktop/Notifications", this);
        } catch (Error e) {
            warning("Unable to register notification dbus: %s", e.message);
        }
    }

    [DBus (visible = false)]
    void serve_dbus()
    {
        Bus.own_name(BusType.SESSION, "org.freedesktop.Notififications",
            BusNameOwnerFlags.NONE,
            on_bus_acquired, null, null);
    }
}

} /* End namespace */

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */
