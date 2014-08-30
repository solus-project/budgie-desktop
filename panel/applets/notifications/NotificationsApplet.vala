/*
 * NotificationsApplet.vala
 * 
 * Copyright 2014 Josh Klar <j@iv597.com>
 * Also Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int ICON_SIZE_PX = 22;
const int PADDING_PX = 10;

const int NOTIFICATION_SHOW_SECONDS = 5000;

const int    NOTIFICATIONS_CLEAR_POPUP_ICON_SIZE_PX = 92;
const string NOTIFICATIONS_CLEAR_POPUP_ICON = "face-smile-big-symbolic";
const string NOTIFICATIONS_CLEAR_ICON = "user-invisible-symbolic";
const string NOTIFICATIONS_UNREAD_ICON = "user-available-symbolic";

const int CRAQMONKEYTIMEMAX = 20000;

[DBus (name = "org.freedesktop.Notifications")]
public class NotificationServer : Object {
    private weak DBusConnection conn;

    /**
     * Used internally to notify the owner of new notifications
     */
    public signal void new_notification(string app_name,
                                        uint32 id,
                                        uint32 replace_id,
                                        string app_icon,
                                        string summary,
                                        string body,
                                        int32 timeout);

    public NotificationServer (DBusConnection conn)
    {
        this.conn = conn;
    }

    public string[] get_capabilities()
    {
        return {"body", "body-markup"};
    }

    public void get_server_information(
        out string name,
        out string vendor,
        out string version,
        out string spec_version) 
    {
        name = "budgie-panel";
        vendor = "Evolve OS";
        version = "0.0.1";
        spec_version = "1";
    }

    public new uint32 notify(
        string app_name,
        uint32 replaces_id, // ignored
        string app_icon,
        string summary,
        string body,
        string[] actions,
        HashTable<string, Variant> hints,
        int32 expire_timeout)
    {
        uint32 hash = (uint32)(app_name.hash() ^ GLib.get_real_time());
        new_notification(app_name, hash, replaces_id, app_icon, summary, body, expire_timeout);

        return hash;
    }
}

public class NotificationsApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new NotificationsAppletImpl();
    }
}

public class NotificationsAppletImpl : Budgie.Applet
{

    private NotificationServer nserver;

    protected Gtk.EventBox widget;
    protected Gtk.Image icon;
    protected Budgie.Popover pop;
    protected Gtk.Box pop_child_outer; // this is so hacky...
    protected Gtk.Box pop_child;
    protected Gtk.Image no_notifications_icon;
    protected Gtk.Label no_notifications_text;
    protected Gtk.Box no_notifications;

    /* We map the given hash to a notification, allowing replacements */
    protected Gee.HashMap<uint32,Notification> notifications;

    protected const int TIMEOUT = 100;
    protected bool managed = false;

    public NotificationsAppletImpl()
    {
        Bus.own_name(BusType.SESSION, "org.freedesktop.Notifications",
            BusNameOwnerFlags.NONE, on_nserver_bus_acquired,
            on_nserver_name_acquired, on_nserver_name_lost);

        notifications = new Gee.HashMap<uint32,Notification>(null, null, null);

        widget = new Gtk.EventBox();
        widget.margin_left = 2;
        widget.margin_right = 2;
        icon = new Gtk.Image.from_icon_name(NOTIFICATIONS_CLEAR_ICON, Gtk.IconSize.INVALID);
        icon.pixel_size = ICON_SIZE_PX;
        widget.add(icon);

        pop = new Budgie.Popover();
        pop.border_width = 6;
        pop_child = new Gtk.Box(Gtk.Orientation.VERTICAL, PADDING_PX);
        pop_child_outer = new Gtk.Box(Gtk.Orientation.HORIZONTAL, PADDING_PX);
        
        pop_child_outer.pack_start(pop_child, true, true, 0);
        pop.add(pop_child_outer);

        widget.button_release_event.connect((e)=> {
            if (e.button == 1) {
                pop.present(icon);
                return true;
            }
            return false;
        });

        no_notifications_icon = new Gtk.Image.from_icon_name(NOTIFICATIONS_CLEAR_POPUP_ICON, Gtk.IconSize.INVALID);
        no_notifications_icon.pixel_size = NOTIFICATIONS_CLEAR_POPUP_ICON_SIZE_PX;

        no_notifications_text = new Gtk.Label(null);
        no_notifications_text.set_markup("<b>All caught up!</b>");

        no_notifications = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        no_notifications.pack_start(no_notifications_icon, false, false, 0);
        no_notifications.pack_start(no_notifications_text, false, false, 0);

        pop_child.pack_start(no_notifications, true, false, PADDING_PX);
        pop.set_size_request(300, 100);

        icon_size_changed.connect((i,s)=> {
            icon.pixel_size = (int)s;
        });
        add(widget);
        show_all();
    }

    private void on_nserver_bus_acquired(DBusConnection conn) {
        try {
            this.nserver = new NotificationServer(conn);
            conn.register_object("/org/freedesktop/Notifications", this.nserver);

            this.nserver.new_notification.connect(on_notification);
        } catch (IOError e) {
            // bail?
        }
    }

    protected Notification? spawn_notification(string app_name,
                                               uint32 id,
                                               uint32 replace_id,
                                               string icon,
                                               string summary,
                                               string body,
                                               uint32 timeout)
    {
        Notification? notif;

        if (replace_id in notifications) {
            /* Update existing notification */
            notif = notifications[replace_id];
            notif.icon_name = icon;
            notif.summary = summary;
            notif.body = body;
        } else {
            /* Slide a new notification in */
            notif = new Notification(summary, body, icon);
            notif.dismiss.connect((h)=> {
                notif.timeout = 1000;
                /* Place holder code, at some point we'll want to slide
                   these fellas out too. */
                ((Gtk.Revealer)notif.get_parent()).set_reveal_child(false);
            });
            notif.app_name = app_name;
        }
        notif.hashid = id;
        notifications[id] = notif;

        if (timeout <= 0 || timeout >= CRAQMONKEYTIMEMAX) {
            notif.timeout = NOTIFICATION_SHOW_SECONDS;
        } else {
            notif.timeout = timeout;
        }
        /* Always reset start time. */
        notif.start_time = GLib.get_real_time () / 1000;

        return notifications[id];
    }

    protected bool manage_notifications()
    {
        Notification[] removals = {};
        uint32[] orphans = {};

        /* Cleanup orphans from replace_id's */
        foreach (var id in notifications.keys) {
            var notification = notifications[id];
            if (id != notification.hashid) {
                orphans += id;
            }
        }
        foreach (var id in orphans) {
            notifications.unset(id);
        }

        if (notifications != null && notifications.size >= 1) {
            foreach (var notification in notifications.values) {
                Gtk.Revealer? parent = (Gtk.Revealer)notification.get_parent();
                var current_time = GLib.get_real_time () / 1000;
                var visible_time = current_time - notification.start_time;
                /* Destroy if its been visible too long */
                if (visible_time >= notification.timeout + parent.get_transition_duration()) {
                    removals += notification;
                } else if (visible_time >= notification.timeout) {
                    /* Set it to hide instead - we reap later */
                    parent.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
                    parent.set_reveal_child(false);
                }
            }
        }
        /* Clean up outside the hashmap iteration */
        foreach (var notification in removals) {
            notifications.unset(notification.hashid);
            notification.get_parent().destroy();
        }
        /* Disconnect ourselves */
        if (notifications.size == 0) {
            this.managed = false;

            this.icon.set_from_icon_name(NOTIFICATIONS_CLEAR_ICON, Gtk.IconSize.INVALID);
            pop.hide();
            pop.passive = false;
            if (no_notifications.get_parent() != pop_child) {
                pop_child.pack_start(no_notifications, true, false, PADDING_PX);
                pop_child.show_all();
            }
            return false;
        }

        /* More notifications to manage, continue */
        return true;
    }

    protected void on_notification(string app_name,
                                   uint32 id,
                                   uint32 replace_id,
                                   string icon,
                                   string summary,
                                   string body,
                                   int32 timeout)
    {
        this.icon.set_from_icon_name(NOTIFICATIONS_UNREAD_ICON, Gtk.IconSize.INVALID);
        pop.passive = true;
        if (no_notifications.get_parent() == pop_child) {
            pop_child.remove(no_notifications);
        }

        Notification? notif = spawn_notification(app_name, id, replace_id, icon, summary, body, timeout);
        if (notif.get_parent() == null) {
            var revealer = new Gtk.Revealer();
            revealer.add(notif);
            revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
            revealer.set_reveal_child(false);
            pop_child.pack_start(revealer, false, false, 0);
        }

        var revealer = (Gtk.Revealer)notif.get_parent();
        /* Ensure animation works for additions while visible */
        if (pop.get_visible() && pop.get_realized()) {
            Idle.add(()=> {
                revealer.set_reveal_child(true);
                return false;
            });
        } else {
            pop.set_size_request(300, 100);
            revealer.set_reveal_child(true);
        }

        pop.present(this.icon);

        /* Once we have an notification we set a background update to check notification timeouts, etc. */
        if (!this.managed) {
            Timeout.add(TIMEOUT, manage_notifications);
        }
    }

    private void on_nserver_name_acquired() {
    }

    private void on_nserver_name_lost(DBusConnection? conn, string name) {
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(NotificationsApplet));
}
