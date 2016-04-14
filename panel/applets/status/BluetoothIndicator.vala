/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * Copyright (C) 2015 Alberts Muktupāvels
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * BluetoothIndicator is largely inspired by gnome-flashback.
 */

[DBus (name="org.gnome.SettingsDaemon.Rfkill")]
public interface Rfkill : Object
{
    public abstract bool BluetoothAirplaneMode { set; get; }
}

public class BluetoothIndicator : Gtk.Bin
{
    public Gtk.Image? image = null;

    public Gtk.EventBox? ebox = null;
    private Bluetooth.Client? client = null;
    private Gtk.TreeModel? model = null;
    public Gtk.Popover? popover = null;

    SimpleAction? send_to = null;
    SimpleAction? airplane = null;
    Rfkill? killer = null;

    async void setup_dbus()
    {
        try {
            killer = yield Bus.get_proxy(BusType.SESSION, "org.gnome.SettingsDaemon.Rfkill", "/org/gnome/SettingsDaemon/Rfkill");
        } catch (Error e) {
            warning("Unable to contact RfKill manager: %s", e.message);
            return;
        }
    }

    bool get_default_adapter(out Gtk.TreeIter adapter)
    {
        Gtk.TreeIter iter;

        if (!model.get_iter_first(out iter)) {
            return false;
        }

        while (true) {
            bool is_default;
            model.get(iter, Bluetooth.Column.DEFAULT, out is_default, -1);
            if (is_default) {
                adapter = iter;
                return true;
            }
            if (!model.iter_next(ref iter)) {
                break;
            }
        }
        return false;
    }

    int get_n_devices()
    {
        Gtk.TreeIter iter;
        Gtk.TreeIter? adapter;
        int n_devices = 0;

        if (!get_default_adapter(out adapter)) {
            return -1;
        }

        if (!model.iter_children(out iter, adapter)) {
            return 0;
        }

        while (true) {
            bool con;
            model.get(iter, Bluetooth.Column.CONNECTED, out con, -1);
            if (con) {
                n_devices++;
            }
            if (!model.iter_next(ref iter)) {
                break;
            }
        }
        return n_devices;
    }

    private void resync()
    {
        var n_devices = get_n_devices();
        string? lbl = null;

        if (killer != null) {
            if (killer.BluetoothAirplaneMode) {
                image.set_from_icon_name("bluetooth-disabled-symbolic", Gtk.IconSize.MENU);
                lbl = _("Bluetooth is disabled");
                n_devices = 0;
            } else {
                image.set_from_icon_name("bluetooth-active-symbolic", Gtk.IconSize.MENU);
                lbl = _("Bluetooth is active");
            }
        }

        if (n_devices > 0) {
            lbl = ngettext("Connected to %d device", "Connected to %d devices", n_devices).printf(n_devices);
            send_to.set_enabled(true);
        } else if (n_devices < 0) {
            hide();
            return;
        } else {
            send_to.set_enabled(false);
        }

        /* TODO: Determine if bluetooth is actually active (rfkill) */
        show();
        image.set_tooltip_text(lbl);
    }

    void on_settings_activate()
    {
        var app_info = new DesktopAppInfo("gnome-bluetooth-panel.desktop");
        if (app_info == null) {
            return;
        }
        try {
            app_info.launch(null, null);
        } catch (Error e) {
            message("Unable to launch gnome-bluetooth-panel.desktop: %s", e.message);
        }
    }

    void on_send_file()
    {
        try {
            var app_info = AppInfo.create_from_commandline("bluetooth-sendto", "Bluetooth Transfer", AppInfoCreateFlags.NONE);
            if (app_info == null) {
                return;
            }

            try {
                app_info.launch(null, null);
            } catch (Error e) {
                message("Unable to launch bluetooth-sendto: %s", e.message);
            }
        } catch (Error e) {
            message("Unable to create bluetooth-sendto AppInfo: %s", e.message);
        }
    }

    public BluetoothIndicator()
    {
        image = new Gtk.Image.from_icon_name("bluetooth-active-symbolic", Gtk.IconSize.MENU);

        ebox = new Gtk.EventBox();
        add(ebox);

        ebox.add(image);

        client = new Bluetooth.Client();
        model = client.get_model();
        model.row_changed.connect(() => { resync(); });
        model.row_deleted.connect(() => { resync(); });
        model.row_inserted.connect(() => { resync(); });

        var menu = new GLib.Menu();
        menu.append(_("Bluetooth Settings"), "bluetooth.settings");
        menu.append(_("Send Files"), "bluetooth.send-file");
        menu.append(_("Bluetooth Airplane Mode"), "bluetooth.airplane-mode");
        popover = new Gtk.Popover.from_model(ebox, menu);

        var group = new GLib.SimpleActionGroup();
        var settings = new GLib.SimpleAction("settings", null);
        settings.activate.connect(on_settings_activate);
        group.add_action(settings);

        send_to = new GLib.SimpleAction("send-file", null);
        send_to.activate.connect(on_send_file);
        group.add_action(send_to);

        airplane = new GLib.SimpleAction.stateful("airplane-mode", null, new Variant.boolean(true));
        airplane.activate.connect(on_set_airplane);
        group.add_action(airplane);
        this.insert_action_group("bluetooth", group);

        this.resync();

        this.setup_dbus.begin(()=> {
            if (this.killer == null) {
                return;
            }
            this.sync_rfkill();
        });

        show_all();
    }

    /* We set */
    void on_set_airplane()
    {
        bool s = !(airplane.get_state().get_boolean());
        try {
            killer.BluetoothAirplaneMode = s;
        } catch (Error e) {
            message("Error setting airplane mode: %s", e.message);
        }
        this.popover.hide();
    }

    /* Notify */
    void on_airplane_change()
    {
        bool b = killer.BluetoothAirplaneMode;
        airplane.set_state(new Variant.boolean(b));
        this.resync();
    }

    void sync_rfkill()
    {
        bool b = killer.BluetoothAirplaneMode;

        var db = killer as DBusProxy;
        db.g_properties_changed.connect(on_airplane_change);
        airplane.set_state(new Variant.boolean(b));
        this.resync();
    }
} // End class
