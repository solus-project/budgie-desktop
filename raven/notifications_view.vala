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

[GtkTemplate (ui = "/com/solus-project/arc/raven/notification.ui")]
public class NotificationWidget : Gtk.Box
{
    public uint32 id;

    [GtkChild]
    private Gtk.Image? image_icon = null;

    [GtkChild]
    private Gtk.Label? label_title = null;

    [GtkChild]
    private Gtk.Label? label_body = null;

    [GtkChild]
    private Gtk.Button? button_close = null;

    [GtkChild]
    private Gtk.ButtonBox? buttonbox_actions = null;

    /* Allow deprecated usage */
    private string[] img_search = {
        "image-path", "image_path"
    };

    HashTable<string,Variant>? hints = null;

    private string? image_path = null;

    public NotificationWidget()
    {
    }

    private async bool set_from_image_path()
    {
        /* Update the icon. */
        string? img_path = null;
        foreach (var img in img_search) {
            var vimg_path = hints.lookup(img);
            if (vimg_path != null) {
                img_path = vimg_path.get_string();
                break;
            }
        }

        /* Take the img_path */
        if (img_path == null) {
            return false;
        }

        /* Don't unnecessarily update the image */
        if (img_path == this.image_path) {
            return true;
        }
    
        this.image_path = img_path;

        try {
            var file = File.new_for_path(image_path);
            var ins = yield file.read_async(Priority.DEFAULT, null);
            Gdk.Pixbuf? pbuf = yield new Gdk.Pixbuf.from_stream_at_scale_async(ins, 48, 48, true, null);
            image_icon.set_from_pixbuf(pbuf);
        } catch (Error e) {
            return false;
        }

        return true;
    }

    public async void set_from_notify(uint32 id, string app_name, string app_icon,
                                        string summary, string body, string[] actions,
                                        HashTable<string, Variant> hints, int32 expire_timeout)
    {
        this.id = id;
        this.hints = hints;

        bool is_img = yield this.set_from_image_path();

        /* Fallback to named icon if no image-path is specified */
        if (!is_img) {
            this.image_path = null;

            if (app_icon != "") {
                image_icon.set_from_icon_name(app_icon, Gtk.IconSize.INVALID);
                image_icon.pixel_size = 48;
            } else {
                image_icon.set_from_icon_name("mail-unread-symbolic", Gtk.IconSize.INVALID);
                image_icon.pixel_size = 48;
            }
        }

        if (summary == "") {
            label_title.set_text(app_name);
        } else {
            label_title.set_text(Markup.escape_text(summary));
        }

        label_body.set_text(Markup.escape_text(body));
    }
}

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
        "body", /*"body-markup",*/ "actions", "action-icons"
    };

    /* Obviously we'll change this.. */
    private HashTable<uint32,NotificationWidget?> notifications;

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

        unowned NotificationWidget? pack = null;
        if (replaces_id > 0) {
            notifications.lookup(replaces_id);
        }

        if (pack == null) {
            var npack = new NotificationWidget();
            notifications.insert(notif_id, npack);
            pack = npack;
        }

        yield pack.set_from_notify(notif_id, app_name, app_icon, summary, body, actions,
            hints, expire_timeout);
        
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

        notifications = new HashTable<uint32,NotificationWidget?>(direct_hash, direct_equal);

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
        Bus.own_name(BusType.SESSION, "org.freedesktop.Notifications",
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
