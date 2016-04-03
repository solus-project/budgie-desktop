/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */
public class StatusPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new StatusApplet();
    }
}

[DBus (name="com.solus_project.budgie.Raven")]
public interface RavenProxy : Object
{
    public abstract async void Toggle() throws Error;
}

public static const string RAVEN_DBUS_NAME        = "com.solus_project.budgie.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/budgie/Raven";

public class StatusApplet : Budgie.Applet
{

    protected Gtk.Box widget;
    protected BluetoothIndicator blue;
    protected SoundIndicator sound;
    protected PowerIndicator power;
    protected Gtk.EventBox? wrap;
    protected RavenProxy? raven_proxy = null;
    private Budgie.PopoverManager? manager = null;

    public StatusApplet()
    {
        wrap = new Gtk.EventBox();
        add(wrap);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrap.add(widget);

        power = new PowerIndicator();
        widget.pack_start(power, false, false, 0);

        sound = new SoundIndicator();
        widget.pack_start(sound, false, false, 2);

        blue = new BluetoothIndicator();
        widget.pack_start(blue, false, false, 2);

        wrap.button_release_event.connect(on_button_release);

        var power = new Gtk.Image.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.MENU);
        widget.pack_start(power, false, false, 2);

        blue.ebox.button_press_event.connect((e)=> {
            if (e.button != 3) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (blue.popover.get_visible()) {
                blue.popover.hide();
            } else {
                this.manager.show_popover(blue.ebox);
            }
            return Gdk.EVENT_STOP;
        });

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

    public override void update_popovers(Budgie.PopoverManager? manager)
    {
        this.manager = manager;
        manager.register_popover(blue.ebox, blue.popover);
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
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(StatusPlugin));
}
