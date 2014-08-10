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

public class ClockAppletImpl : Budgie.Applet
{

    protected Gtk.EventBox widget;
    protected Gtk.Label clock;
    protected Gtk.Calendar cal;
    protected Budgie.Popover pop;

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

    /**
     * This is called once every second, updating the time
     */
    protected bool update_clock()
    {
        DateTime time = new DateTime.now_local();
        var ftime = time.format(" <big>%H:%M </big> ");
        clock.set_markup(ftime);

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
