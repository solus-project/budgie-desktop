/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2014 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ClockPlugin : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget()
    {
        return new ClockApplet();
    }
}

enum ClockFormat {
    TWENTYFOUR = 0,
    TWELVE = 1;
}

public static const string CALENDAR_MIME = "text/calendar";

public class ClockApplet : Arc.Applet
{

    protected Gtk.EventBox widget;
    protected Gtk.Label clock;

    protected bool ampm = false;
    protected bool show_seconds = false;
    protected bool show_date = false;

    private DateTime time;

    protected Settings settings;

    Gtk.Popover? popover = null;
    AppInfo? calprov = null;

    public ClockApplet()
    {
        widget = new Gtk.EventBox();
        clock = new Gtk.Label("");
        time = new DateTime.now_local();
        widget.add(clock);


        var menu = new GLib.Menu();
        menu.append(_("Time and date settings"), "clock.time_and_date");
        menu.append(_("Calendar"), "clock.calendar");
        popover = new Gtk.Popover.from_model(widget, menu);

        popover.get_child().show_all();

        widget.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.show_all();
            }
            return Gdk.EVENT_STOP;
        });

        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);

        settings = new Settings("org.gnome.desktop.interface");
        settings.changed.connect(on_settings_change);
        on_settings_change("clock-format");
        on_settings_change("clock-show-seconds");
        on_settings_change("clock-show-date");

        var group = new GLib.SimpleActionGroup();
        var date = new GLib.SimpleAction("time_and_date", null);
        date.activate.connect(on_date_activate);
        group.add_action(date);

        /* TODO: Listen for app changes */
        calprov = AppInfo.get_default_for_type(CALENDAR_MIME, false);

        this.insert_action_group("clock", group);
        var cal = new GLib.SimpleAction("calendar", null);
        cal.set_enabled(calprov != null);
        cal.activate.connect(on_cal_activate);
        group.add_action(cal);

        update_clock();
        add(widget);
        show_all();
    }

    void on_date_activate()
    {
        var app_info = new DesktopAppInfo("gnome-datetime-panel.desktop");

        if (app_info == null) {
            return;
        }
        try {
            app_info.launch(null, null);
        } catch (Error e) {
            message("Unable to launch gnome-datetime-panel.desktop: %s", e.message);
        }
    }

    void on_cal_activate()
    {
        if (calprov == null) {
            return;
        }
        try {
            calprov.launch(null, null);
        } catch (Error e) {
            message("Unable to launch %s: %s", calprov.get_name(), e.message);
        }
    }

    public override void update_popovers(Arc.PopoverManager? manager)
    {
        manager.register_popover(widget, popover);
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
        time = new DateTime.now_local();
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
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(ClockPlugin));
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
