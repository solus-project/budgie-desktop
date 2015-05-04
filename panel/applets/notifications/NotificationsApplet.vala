/*
 * NotificationsApplet.vala
 * 
 * Copyright 2014 Josh Klar <j@iv597.com>
 * Also Copyright 2014 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const string NOTIFICATIONS_CLEAR_ICON = "user-invisible-symbolic";
const string NOTIFICATIONS_UNREAD_ICON = "user-available-symbolic";

public class NotificationsApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new NotificationsAppletImpl();
    }
}

[DBus (name = "org.freedesktop.Notifications")]
public class NotificationServer : Object
{
    private weak DBusConnection conn;

    /**
     * Used internally to notify the owner of new notifications
     */
    [DBus (visible = false)] 
    public signal void new_notification(string app_name,
                                        uint32 id,
                                        uint32 replace_id,
                                        string app_icon,
                                        string summary,
                                        string body,
                                        int32 timeout,
                                        HashTable<string,Variant> hints,
                                        string[] actions);

    public NotificationServer (DBusConnection conn)
    {
        this.conn = conn;
    }

    public string[] get_capabilities()
    {
        return {"body", "body-markup", "actions", "action-icons"};
    }

    public void get_server_information(
        out string name,
        out string vendor,
        out string version,
        out string spec_version) 
    {
        name = "budgie-panel";
        vendor = "Solus Project";
        version = "0.0.2";
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
        new_notification(app_name, hash, replaces_id, app_icon, summary, body, expire_timeout, hints, actions);

        return hash;
    }

    public signal void action_invoked(uint32 id, string action_id);
}

public struct Notif {
    uint32 id;
    uint32 replace_id;
    string app_icon;
    string summary;
    string body;
    int32 timeout;
    string? image_path;
    bool icons;
    string[] actions;
}
/**
 * Or, dbus owner.
 */
public class NotificationsAppletImpl : Budgie.Applet
{

    NotificationServer nserver;
    List<NotificationWidget?> notifs;
    public bool use_dark_theme { public set; public get; }

    Settings st;
    Gtk.EventBox widget;
    Gtk.Image icon;

    public NotificationsAppletImpl()
    {
        st = new Settings("com.evolve-os.budgie.panel");
        st.bind("dark-theme", this, "use-dark-theme", SettingsBindFlags.DEFAULT);
        widget = new Gtk.EventBox();
        widget.margin_start = 2;
        widget.margin_end = 2;
        icon = new Gtk.Image.from_icon_name(NOTIFICATIONS_CLEAR_ICON, Gtk.IconSize.INVALID);
        widget.add(icon);;

        icon_size_changed.connect((i,s)=> {
            icon.pixel_size = (int)s;
        });

        Bus.own_name(BusType.SESSION, "org.freedesktop.Notifications",
            BusNameOwnerFlags.NONE, on_nserver_bus_acquired,
            on_nserver_name_acquired, on_nserver_name_lost);

        add(widget);
        show_all();
    }

    private void on_nserver_bus_acquired(DBusConnection conn)
    {
        try {
            this.nserver = new NotificationServer(conn);
            conn.register_object("/org/freedesktop/Notifications", this.nserver);

            /* Why this assortment of madness? We don't want to block dbus. */
            this.nserver.new_notification.connect((app_name, hash, replaces_id, app_icon, summary, body, expire_timeout, hints, actions)=> {
                var notif = Notif() {
                    id = hash,
                    replace_id = replaces_id,
                    app_icon = app_icon,
                    summary = summary,
                    body = body,
                    timeout = expire_timeout,
                    actions = actions
                };

                var ic = hints.lookup("image-path");
                if (ic == null) {
                    ic = hints.lookup("image_path");
                }

                if (ic != null) {
                    notif.image_path = ic.get_string();
                }

                var b = hints.lookup("action-icons");
                if (b != null) {
                    if (b.get_boolean() == true) {
                        notif.icons = true;
                    }
                }
                Idle.add(()=> {
                    on_notification(notif);
                    return false;
                });
            });
        } catch (IOError e) {
            // bail?
            message(e.message);
        }
    }

    void on_notification(Notif notif)
    {
        NotificationWidget? n = null;

        /* find one to replace, we're using a list because in future
         * we'll support merging */
        for (uint i = 0; i < notifs.length(); i++) {
            var t = notifs.nth_data(i);
            if (t.id == notif.replace_id) {
                n = t;
                break;
            }
        }

        /* Sane timeouts please.. */
        if (notif.timeout < 4000) {
            notif.timeout = 4000;
        } else if (notif.timeout > 20000) {
            notif.timeout = 20000;
        }

        icon.set_from_icon_name(NOTIFICATIONS_UNREAD_ICON, Gtk.IconSize.INVALID);

        if (n == null) {
            /* New notification.. */
            n = new NotificationWidget(nserver, notif);

            if (this.use_dark_theme) {
                /* So yeah, pita to give dark theming via Gtk. So we force our own defaults.. */
                n.get_settings().set_property("gtk-application-prefer-dark-theme", true);
                n.get_style_context().add_class("dark");
            } else {
                n.get_settings().set_property("gtk-application-prefer-dark-theme", false);
            }
            var win = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
            win.get_style_context().add_class("budgie-notification");
            win.type_hint = Gdk.WindowTypeHint.NOTIFICATION;
            win.set_visual(win.get_screen().get_rgba_visual());
            win.add(n);
            win.border_width = 10;
            n.show_all();
            n.dismiss.connect(()=> {
                notifs.remove(n);
                n.get_parent().hide();
                Idle.add(()=> {
                    n.get_parent().destroy();
                    return false;
                });
                if (notifs.length() == 0) {
                    icon.set_from_icon_name(NOTIFICATIONS_CLEAR_ICON, Gtk.IconSize.INVALID);
                }
            });
        } else {
            /* Reuse and bail */
            n.timeout = notif.timeout;
            n.update(notif);
            return;
        }

        /* May seem counter-intuitive handling windows separately to their
         * container-child, but this will just make it easier to fix things
         * in the future for Wayland support (position, etc.). Less to
         * change */
        var win = n.get_parent() as Gtk.Window;
        var screen = win.get_screen();
        int m = screen.get_primary_monitor();
        Gdk.Rectangle rect;
        rect = screen.get_monitor_workarea(m);

        n.timeout = notif.timeout;
        var buf_pad = 5;
        /* Top right corner.. */
        var y = rect.y + buf_pad;
        if (notifs.length() > 0) {
            var i = notifs.last().data;
            int ix;
            (i.get_parent() as Gtk.Window).get_position(out ix, out y);
            y += i.get_allocated_height();
            y += buf_pad;
        }

        win.realize();
        var width = win.get_allocated_width();
        var x = ((rect.x + rect.width) - width) - buf_pad;
        win.move(x, y);
        win.set_decorated(false);
        win.show_all();

        notifs.append(n);
    }

    /* Reserved.. */
    private void on_nserver_name_acquired()
    {
    }
    private void on_nserver_name_lost(DBusConnection? conn, string name)
    {
    }
}
[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(NotificationsApplet));
}
