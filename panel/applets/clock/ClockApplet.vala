/*
 * ClockApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ClockApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new ClockAppletImpl();
    }
}

enum ClockFormat {
    TWENTYFOUR = 0,
    TWELVE = 1;
}

public class ClockAppletImpl : Budgie.Applet
{

    protected Gtk.EventBox widget;
    protected Gtk.Label clock;
    protected Gtk.Calendar cal;
    protected Budgie.Popover pop;

    protected bool ampm = false;
    protected bool show_seconds = false;
    protected bool show_date = false;

    protected Settings settings;

    public ClockAppletImpl()
    {
        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        cal = new Gtk.Calendar();
        widget.add(clock);

        // Interesting part - calender in a popover :)
        pop = new Budgie.Popover();

        widget.button_release_event.connect((e)=> {
            if (e.button == 1) {
                pop.present(clock);
                return true;
            }
            return false;
        });
        pop.add(cal);
        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);

        settings = new Settings("org.gnome.desktop.interface");
        settings.changed.connect(on_settings_change);
        on_settings_change("clock-format");
        on_settings_change("clock-show-seconds");
        on_settings_change("clock-show-date");
        update_clock();
        add(widget);
        show_all();
        position_changed.connect(on_position_change);
    }

    protected void on_position_change(Budgie.PanelPosition position)
    {
        switch (position) {
            case Budgie.PanelPosition.LEFT:
                clock.set_angle(90);
                break;
            case Budgie.PanelPosition.RIGHT:
                clock.set_angle(-90);
                break;
            default:
                clock.set_angle(0);
                break;
        }
    }

    protected void on_settings_change(string key)
    {
        switch (key) {
            case "clock-format":
                ClockFormat f = (ClockFormat)settings.get_enum(key);
                ampm = f == ClockFormat.TWELVE;
                break;
            case "clock-show-seconds":
                show_seconds = settings.get_boolean(key);
                break;
            case "clock-show-date":
                show_date = settings.get_boolean(key);
                break;
        }
        /* Lazy update on next clock sync */
    }

    /**
     * This is called once every second, updating the time
     */
    protected bool update_clock()
    {
        DateTime time = new DateTime.now_local();
        string format;

        if (ampm) {
            format = "%l:%M";
        } else {
            format = "%H:%M";
        }
        if (show_seconds) {
            format += ":%S";
        }
        if (ampm) {
            format += " %p";
        }
        string ftime = " <big>%s</big> ".printf(format);
        if (show_date) {
            ftime += " <big>%x</big>";
        }

        var ctime = time.format(ftime);
        clock.set_markup(ctime);

        return true;
    }

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ClockApplet));
}
