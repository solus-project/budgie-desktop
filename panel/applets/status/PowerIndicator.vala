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
        this.battery = battery;
    }
}

public class PowerIndicator : Gtk.Bin
{

    /** Widget containing battery icons to display */
    public Gtk.Box widget { protected set; public get; }

    /** Our upower client */
    public Up.Client client { protected set; public get; }

    /** Device references */
    protected List<unowned Up.Device> batteries;

    public PowerIndicator()
    {
        batteries = new List<Up.Device>();

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        add(widget);

        client = new Up.Client();
        update_ui();
    }

    /**
     * Update our UI as our battery (in interest) changed/w/e
     */
    protected void update_ui()
    {
        // try to discover batteries
        var devices = client.get_devices();

        devices.foreach((device) => {
            if (device.kind != Up.DeviceKind.BATTERY) {
                return;
            }

            bool alreadyContained = false;
            batteries.foreach((battery) => {
                if (device.serial == battery.serial) alreadyContained = true;
            });

            if (!alreadyContained) {
            	batteries.append(device);
                device.notify.connect(() => update_ui ());
            }
        });
        if (batteries.length() == 0) {
            warning("Unable to discover a battery");
            remove(widget);
            hide();
            return;
        }
        hide();

        // Update/add icon for each battery
        batteries.foreach((battery) => {
            string tip = "Battery "; // Initially setting tooltip to Battery 

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
                    tip += "fully charged."; // Imply the battery is charged
            } else if (battery.state == 1) {
                    image_name += "-charging-symbolic";
                    string time_to_full_str = "Unknown"; // Default time_to_full_str to Unknown
                    int time_to_full = (int)battery.time_to_full; // Seconds for battery time_to_full

                    if (time_to_full > 0) { // If TimeToFull is known
                            int hours = time_to_full / (60 * 60);
                            int minutes = time_to_full / 60 - hours * 60;
                            time_to_full_str = "%d:%02d".printf(hours, minutes); // Set inner charging duration to hours:minutes
                    }

                    tip += "charging: %d%% (%s)".printf((int)battery.percentage, time_to_full_str); // Set to charging: % (Unknown/Time)
            } else {
                    image_name += "-symbolic";
                    int hours = (int)battery.time_to_empty / (60 * 60);
                    int minutes = (int)battery.time_to_empty / 60 - hours * 60;
                    tip += "remaining: %d%% (%d:%02d)".printf((int)battery.percentage, hours, minutes);
            }

            // Determine BatteryIcon that corresponds to the battery
            BatteryIcon icon = null;
            widget.get_children().foreach((child) => {
                BatteryIcon childIcon = (BatteryIcon) child;
                if (childIcon.battery.serial == battery.serial) {
                    icon = childIcon;
                }
            });
            // If not already contained, create new BatteryIcon
            if (icon == null) {
                icon = new BatteryIcon(battery);
                widget.pack_end(icon);
            }

            // Set a handy tooltip until we gain a menu in StatusApplet

            icon.set_tooltip_text(tip);
            icon.set_from_icon_name(image_name, Gtk.IconSize.MENU);
        });

        show_all();
    }
} // End class
