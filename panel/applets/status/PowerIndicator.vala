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

public class BatteryIcon : Gtk.Image
{
    /** The battery associated with this icon */
    public unowned Up.Device battery { protected set; public get; }

    public BatteryIcon(Up.Device battery) {
        this.update_ui(battery);
    }

    public void update_ui(Up.Device battery)
    {
        string tip;

        this.battery = battery;

        // Determine the icon to use for this battery
        string image_name;
        if (battery.percentage <= 10) {
            image_name = "battery-empty";
        } else if (battery.percentage <= 35) {
            image_name = "battery-low";
        } else if (battery.percentage <= 75) {
            image_name = "battery-good";
        } else {
            image_name = "battery-full";
        }

        // Fully charged OR charging
        if (battery.state == 4) {
                image_name = "battery-full-charged-symbolic";
                tip = _("Battery fully charged."); // Imply the battery is charged
        } else if (battery.state == 1) {
                image_name += "-charging-symbolic";
                string time_to_full_str = _("Unknown"); // Default time_to_full_str to Unknown
                int time_to_full = (int)battery.time_to_full; // Seconds for battery time_to_full

                if (time_to_full > 0) { // If TimeToFull is known
                        int hours = time_to_full / (60 * 60);
                        int minutes = time_to_full / 60 - hours * 60;
                        time_to_full_str = "%d:%02d".printf(hours, minutes); // Set inner charging duration to hours:minutes
                }

                tip = _("Battery charging") + ": %d%% (%s)".printf((int)battery.percentage, time_to_full_str); // Set to charging: % (Unknown/Time)
        } else {
                image_name += "-symbolic";
                int hours = (int)battery.time_to_empty / (60 * 60);
                int minutes = (int)battery.time_to_empty / 60 - hours * 60;
                tip = _("Battery remaining") + ": %d%% (%d:%02d)".printf((int)battery.percentage, hours, minutes);
        }

        // Set a handy tooltip until we gain a menu in StatusApplet

        set_tooltip_text(tip);
        set_from_icon_name(image_name, Gtk.IconSize.MENU);
        this.queue_draw();
    }
}

public class PowerIndicator : Gtk.Bin
{

    /** Widget containing battery icons to display */
    public Gtk.Box widget { protected set; public get; }

    /** Our upower client */
    public Up.Client client { protected set; public get; }

    private HashTable<string,BatteryIcon?> devices;

    public PowerIndicator()
    {
        devices = new HashTable<string,BatteryIcon?>(str_hash, str_equal);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        add(widget);

        client = new Up.Client();

        this.sync_devices();
        client.device_added.connect(this.on_device_added);
        client.device_removed.connect(this.on_device_removed);
        toggle_show();
    }

    private bool is_interesting(Up.Device device)
    {
        /* TODO: Add support for mice, etc. */
        if (device.kind != Up.DeviceKind.BATTERY) {
            return false;
        }
        return true;
    }

    /**
     * Add a new device to the tree
     */
    void on_device_added(Up.Device device)
    {
        if (devices.contains(device.serial)) {
            /* Treated as a change event */
            devices.lookup(device.serial).update_ui(device);
            return;
        }
        if (!this.is_interesting(device)) {
            return;
        }
        var icon = new BatteryIcon(device);
        devices.insert(device.serial, icon);
        widget.pack_start(icon);
        toggle_show();
    }


    void toggle_show()
    {
        if (devices.size() < 1) {
            hide();
        } else {
            show_all();
        }
    }

    /**
     * Remove a device from our display
     */
    void on_device_removed(Up.Device device) {
        if (!devices.contains(device.serial)) {
            return;
        }
        unowned BatteryIcon? icon = devices.lookup(device.serial);
        widget.remove(icon);
        devices.remove(device.serial);
        toggle_show();
    }

    private void sync_devices()
    {
        // try to discover batteries
        var devices = client.get_devices();

        devices.foreach((device) => {
            this.on_device_added(device);

        });
        if (this.devices.size() == 0) {
            warning("Unable to discover a battery");
        }
        toggle_show();
    }
} // End class
