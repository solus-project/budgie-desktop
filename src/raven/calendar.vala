/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class CalendarWidget : Gtk.Box
{

    private Gtk.Calendar? cal = null;
    private Budgie.HeaderWidget? header = null;

    private const string date_format = "%e %b %Y";

    public CalendarWidget()
    {
        Object(orientation: Gtk.Orientation.VERTICAL);
        var time = new DateTime.now_local();
        header = new Budgie.HeaderWidget(time.format(date_format), "x-office-calendar-symbolic", false);
        var expander = new Budgie.RavenExpander(header);
        this.pack_start(expander, false, false, 0);

        cal = new Gtk.Calendar();
        cal.get_style_context().add_class("raven-calendar");
        var ebox = new Gtk.EventBox();
        ebox.get_style_context().add_class("raven-background");
        ebox.add(cal);
        expander.add(ebox);

        Timeout.add_seconds_full(GLib.Priority.LOW, 30, this.update_date);
    }

    private bool update_date()
    {
        var time = new DateTime.now_local();
        var strf = time.format(date_format);
        header.text = strf;
        cal.day = time.get_day_of_month();
        return true;
    }

} // End class

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
