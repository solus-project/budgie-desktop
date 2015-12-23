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

public class NotificationsPlugin : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget()
    {
        return new NotificationsApplet();
    }
}

public static const string RAVEN_DBUS_NAME        = "com.solus_project.arc.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/arc/Raven";

[DBus (name="com.solus_project.arc.Raven")]
public interface RavenRemote : Object
{
    public abstract async void Toggle() throws Error;
    public abstract async void ToggleNotification() throws Error;
}

public class NotificationsApplet : Arc.Applet
{

    Gtk.EventBox? widget;
    Gtk.Image? icon;
    RavenRemote? raven_proxy = null;

    /* Hold onto our Raven proxy ref */
    void on_raven_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            raven_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to gain Raven proxy: %s", e.message);
        }
    }


    bool on_button_release(Gdk.EventButton? button)
    {
        if (raven_proxy == null) {
            return Gdk.EVENT_PROPAGATE;
        }
    
        if (button.button != 1) {
            return Gdk.EVENT_PROPAGATE;
        }
        try {
            raven_proxy.ToggleNotification();
        } catch (Error e) {
            message("Failed to toggle Raven: %s", e.message);
        }
        return Gdk.EVENT_STOP;
    }

    public NotificationsApplet()
    {
        widget = new Gtk.EventBox();
        add(widget);

        icon = new Gtk.Image.from_icon_name("notification-alert-symbolic", Gtk.IconSize.MENU);
        widget.add(icon);

        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        Bus.get_proxy.begin<RavenRemote>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);

        widget.button_release_event.connect(on_button_release);

        show_all();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(NotificationsPlugin));
}

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
