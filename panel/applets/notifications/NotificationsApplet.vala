/*
 * NotificationsApplet.vala
 * 
 * Copyright 2014 Josh Klar <j@iv597.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int ICON_SIZE_PX = 22;
const int PADDING_PX = 10;

const int NOTIFICATION_SHOW_SECONDS = 5;

const int    NOTIFICATIONS_CLEAR_POPUP_ICON_SIZE_PX = 92;
const string NOTIFICATIONS_CLEAR_POPUP_ICON = "face-smile-big-symbolic";
const string NOTIFICATIONS_CLEAR_ICON = "user-invisible-symbolic";
const string NOTIFICATIONS_UNREAD_ICON = "user-available-symbolic";

[DBus (name = "org.freedesktop.Notifications")]
public class NotificationServer : Object {
    private weak DBusConnection conn;
    private uint32 counter;

    /**
     * Used internally to notify the owner of new notifications
     */
    public signal void new_notification(string app_name, string app_icon, string summary, string body, int32 timeout);

    public NotificationServer (DBusConnection conn)
    {
        this.conn = conn;
        this.counter = -1;
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
        string app_icon, // ignored
        string summary,
        string body,
        string[] actions,
        HashTable<string, Variant> hints,
        int32 expire_timeout)
    {
        this.counter++;
        new_notification(app_name, app_icon, summary, body, expire_timeout);
        return this.counter;
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

    int num_notifications = 0;

    public NotificationsAppletImpl()
    {
        Bus.own_name(BusType.SESSION, "org.freedesktop.Notifications",
            BusNameOwnerFlags.NONE, on_nserver_bus_acquired,
            on_nserver_name_acquired, on_nserver_name_lost);

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

    protected void on_notification(string app_name, string icon, string summary, string body, int32 timeout)
    {
        this.icon.set_from_icon_name(NOTIFICATIONS_UNREAD_ICON, Gtk.IconSize.INVALID);
        pop.passive = true;
        pop_child.remove(no_notifications);

        /* Slide a new notification in */
        var notif = new Notification(summary, body, icon);
        var revealer = new Gtk.Revealer();
        revealer.add(notif);
        revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
        revealer.set_reveal_child(false);
        pop_child.pack_start(revealer, false, false, 0);

        Idle.add(()=>{
            revealer.set_reveal_child(true);
            return false;
        });
        pop.present(this.icon);

        num_notifications += 1;

        if (timeout <= 0) {
            timeout = NOTIFICATION_SHOW_SECONDS * 1000;
        }

        Timeout.add(timeout, () => {
            revealer.destroy();
            num_notifications -= 1;
            /* hide only when the count reaches 0. */
            if (num_notifications == 0) {
                this.icon.set_from_icon_name(NOTIFICATIONS_CLEAR_ICON, Gtk.IconSize.INVALID);
                pop.hide();
                pop.passive = false;
                pop_child.pack_start(no_notifications, true, false, PADDING_PX);

            }
            return false;
        });
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
