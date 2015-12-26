/*
 * StatusApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
public class StatusPlugin : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget(string uuid)
    {
        return new StatusApplet();
    }
}

[DBus (name="com.solus_project.arc.Raven")]
public interface RavenProxy : Object
{
    public abstract async void Toggle() throws Error;
}

public static const string RAVEN_DBUS_NAME        = "com.solus_project.arc.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/arc/Raven";

public class StatusApplet : Arc.Applet
{

    protected Gtk.Box widget;
    protected SoundIndicator sound;
    protected PowerIndicator power;
    protected Gtk.Popover popover;
    protected Gtk.EventBox? wrap;
    protected RavenProxy? raven_proxy = null;

    public StatusApplet()
    {
        wrap = new Gtk.EventBox();
        add(wrap);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        wrap.add(widget);

        power = new PowerIndicator();
        widget.pack_start(power, false, false, 0);

        sound = new SoundIndicator();
        widget.pack_start(sound, false, false, 0);

        wrap.button_release_event.connect(on_button_release);

        var power = new Gtk.Image.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.MENU);
        widget.pack_start(power, false, false, 0);

        show_all();

        setup_dbus();
    }

    bool on_button_release(Gdk.EventButton? button)
    {
        if (button.button != 1) {
            return Gdk.EVENT_PROPAGATE;
        }
        try {
            raven_proxy.Toggle.begin();
        } catch (Error e) {
            message("Unable to toggle Raven");
        }
        return Gdk.EVENT_STOP;
    }


    /* Hold onto our Raven proxy ref */
    void on_raven_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            raven_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to gain Raven proxy: %s", e.message);
        }
    }


    /* Set up the proxy when raven appears */
    void setup_dbus()
    {
        if (raven_proxy == null) {
            Bus.get_proxy.begin<RavenProxy>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);
            return;
        }
    }

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(StatusPlugin));
}
