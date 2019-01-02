/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2019 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class BatteryIcon : Gtk.Box
{
    /** The battery associated with this icon */
    public unowned Up.Device battery { protected set; public get; }
    bool changing = false;

    private Gtk.Image image;

    private Gtk.Label percent_label;

    /**
     * Expose a simple property so the UI can update whether we show
     * labels or not
     */
    public bool label_visible {
        public set {
            this.percent_label.visible = value;
        }
        public get {
            return this.percent_label.visible;
        }
        //default = false;
    }

    public BatteryIcon(Up.Device battery) {
        Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 0);

        this.get_style_context().add_class("battery-icon");

        /* We'll optionally show percent labels */
        this.percent_label = new Gtk.Label("");
        this.percent_label.get_style_context().add_class("percent-label");

        this.percent_label.valign = Gtk.Align.CENTER;
        this.percent_label.margin_end = 4;
        pack_start(this.percent_label, false, false, 0);
        this.percent_label.no_show_all = true;

        this.image = new Gtk.Image();
        this.image.valign = Gtk.Align.CENTER;
        this.image.pixel_size = 0;
        pack_start(this.image, false, false, 0);

        this.update_ui(battery);

        battery.notify.connect(this.on_battery_change);
    }

    private void on_battery_change(Object o, ParamSpec sp)
    {
        if (this.changing) {
            return;
        }
        this.changing = true;
        try {
            this.battery.refresh_sync(null);
        } catch (Error e) {
            warning("Failed to refresh battery: %s", e.message);
        }

        this.update_ui(this.battery);
        this.changing = false;
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

        // Set the percentage label text if it's changed
        string labe = "%d%%".printf((int)battery.percentage);
        string old = this.percent_label.get_label();
        if (old != labe) {
            this.percent_label.set_text(labe);
        }

        // Set a handy tooltip until we gain a menu in StatusApplet
        set_tooltip_text(tip);
        this.image.set_from_icon_name(image_name, Gtk.IconSize.MENU);
        this.queue_draw();
    }
}

public class PowerIndicator : Gtk.Bin
{

    /** Widget containing battery icons to display */
    public Gtk.EventBox? ebox = null;
    public Budgie.Popover? popover = null;
    private Gtk.Box widget = null;

    /** Our upower client */
    public Up.Client client { protected set; public get; }

    private HashTable<string,BatteryIcon?> devices;

    public bool label_visible { set ; get ; default = false; }
    private Gtk.CheckButton check_percent;
    private Settings battery_settings;

    public PowerIndicator()
    {
        devices = new HashTable<string,BatteryIcon?>(str_hash, str_equal);
        ebox = new Gtk.EventBox();
        add(ebox);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        ebox.add(widget);

        popover = new Budgie.Popover(ebox);
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
        box.border_width = 6;
        popover.add(box);

        /* Instaniate label_visible */
        battery_settings = new Settings("org.gnome.desktop.interface");
        battery_settings.bind("show-battery-percentage", this, "label-visible", SettingsBindFlags.GET);
        notify["label-visible"].connect_after(this.update_labels);


        check_percent = new Gtk.CheckButton.with_label(_("Show battery percentage"));
        check_percent.get_child().set_property("margin", 4);
        box.pack_start(check_percent, false, false, 0);
        battery_settings.bind("show-battery-percentage", check_percent, "active", SettingsBindFlags.DEFAULT);

        var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        box.pack_start(sep, false, false, 1);

        var button = new Gtk.Button.with_label(_("Power settings"));
        button.get_style_context().add_class(Gtk.STYLE_CLASS_FLAT);
        button.clicked.connect(open_power_settings);
        button.get_child().set_halign(Gtk.Align.START);
        box.pack_start(button, false, false, 0);
        box.show_all();

        client = new Up.Client();

        this.sync_devices();
        client.device_added.connect(this.on_device_added);
        client.device_removed.connect(this.on_device_removed);
        toggle_show();
    }

    public void change_orientation(Gtk.Orientation orient)
    {
        int spacing = 0;
        if (orient == Gtk.Orientation.VERTICAL) {
            spacing = 5;
        }
        unowned BatteryIcon? icon = null;
        var iter = HashTableIter<string,BatteryIcon?>(this.devices);
        while (iter.next(null, out icon)) {
            icon.set_spacing(spacing);
            icon.set_orientation(orient);
        }
    }

    private void update_labels()
    {
        unowned BatteryIcon? icon = null;
        var iter = HashTableIter<string,BatteryIcon?>(this.devices);
        while (iter.next(null, out icon)) {
            icon.label_visible = this.label_visible;
        }
        /* Fix glitching with Arc theming + "theme-regions" */
        this.get_toplevel().queue_draw();
    }

    private bool is_interesting(Up.Device device)
    {
        /* TODO: Add support for mice, etc. */
        if (device.kind != Up.DeviceKind.BATTERY) {
            return false;
        }
        return true;
    }

    void open_power_settings() {
        popover.hide();

        var app_info = new DesktopAppInfo("gnome-power-panel.desktop");

        if (app_info == null) {
            return;
        }

        try {
            app_info.launch(null, null);
        } catch (Error e) {
            message("Unable to launch gnome-power-panel.desktop: %s", e.message);
        }
    }

    /**
     * Add a new device to the tree
     */
    void on_device_added(Up.Device device)
    {
        string object_path = device.get_object_path();
        if (devices.contains(object_path)) {
            /* Treated as a change event */
            devices.lookup(object_path).update_ui(device);
            return;
        }
        if (!this.is_interesting(device)) {
            return;
        }
        var icon = new BatteryIcon(device);
        icon.label_visible = this.label_visible;
        devices.insert(object_path, icon);
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
    void on_device_removed(string object_path) {
        if (!devices.contains(object_path)) {
            return;
        }
        unowned BatteryIcon? icon = devices.lookup(object_path);
        widget.remove(icon);
        devices.remove(object_path);
        toggle_show();
    }

    private void sync_devices()
    {
        // try to discover batteries
        var devices = client.get_devices();

        devices.foreach((device) => {
            this.on_device_added(device);

        });
        toggle_show();
    }
} // End class
