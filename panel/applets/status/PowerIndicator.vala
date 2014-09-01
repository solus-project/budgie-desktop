/*
 * PowerIndicator.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class PowerIndicator : Gtk.Bin
{

    /** Current image to display */
    public Gtk.Image widget { protected set; public get; }

    /** Our upower client */
    public Up.Client client { protected set; public get; }

    /** Device reference */
    protected unowned Up.Device? battery = null;

    public PowerIndicator()
    {
        widget = new Gtk.Image();
        widget.pixel_size = icon_size;
        add(widget);

        client = new Up.Client();
#if ! HAVE_UPOWER0999
        client.device_changed.connect(update_device);
#endif
        update_ui();
    }

#if ! HAVE_UPOWER0999
    protected void update_device(Up.Device device)
    {
        if (device == battery) {
            update_ui();
        }
    }
#endif
    /**
     * Update our UI as our battery (in interest) changed/w/e
     */
    protected void update_ui()
    {
        if (battery == null) {
            // try to discover the battery
#if ! HAVE_UPOWER0999
            try {
                client.enumerate_devices_sync(null);
            } catch (Error e) {
                warning("Unable to enumerate devices");
                return;
            }
#endif
            var devices = client.get_devices();

            devices.foreach((device) => {
                if (device.kind == Up.DeviceKind.BATTERY && battery == null) {
                    battery = device;
                }
            });
            if (battery == null) {
                warning("Unable to discover a battery");
                remove(widget);
                hide();
                return;
            }
            hide();
        }

        // Got a battery, determine the icon to use
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
        } else if (battery.state == 1) {
                image_name += "-charging-symbolic";
        } else {
                image_name += "-symbolic";
        }

        // Set a handy tooltip until we gain a menu in StatusApplet
        string tip = "Battery remaining: %d%%".printf((int)battery.percentage);
        set_tooltip_text(tip);
        margin = 2;

        widget.set_from_icon_name(image_name, Gtk.IconSize.INVALID);
        show_all();
    }
} // End class
