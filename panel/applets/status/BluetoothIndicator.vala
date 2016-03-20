/*
 * BluetoothIndicator.vala
 *
 * Copyright 2016 Ikey Doherty <ikey@solus-project.com>
 * Copyright (C) 2015 Alberts Muktupāvels
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * BluetoothIndicator is largely inspired by gnome-flashback.
 */

public class BluetoothIndicator : Gtk.Bin
{
    public Gtk.Image? image = null;

    public Gtk.EventBox? ebox = null;
    private Bluetooth.Client? client = null;
    private Gtk.TreeModel? model = null;
    public Gtk.Popover? popover = null;


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

        if (n_devices > 0) {
            lbl = ngettext("Connected to %d device", "Connected to %d devices", n_devices).printf(n_devices);
        } else if (n_devices < 0) {
            hide();
            return;
        }

        /* TODO: Determine if bluetooth is actually active (rfkill) */
        show();
        image.set_tooltip_text(lbl);
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
        popover = new Gtk.Popover.from_model(ebox, menu);

        this.resync();

        show_all();
    }
} // End class
