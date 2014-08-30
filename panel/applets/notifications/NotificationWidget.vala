/*
 * NotificationWidget.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

/**
 * Currently unused, but represents priority hint of notification
 */
public enum NotificationPriority {
    LOW = 0,
    NORMAL,
    CRITICAL
}

/**
 * Simply a visual hint to the priority
 */
public class PriorityIndicator : Gtk.EventBox
{

    public PriorityIndicator(NotificationPriority p)
    {
        var st = get_style_context();
        st.add_class("priority");
        st.remove_class("background");

        switch (p)
        {
            case NotificationPriority.LOW:
                st.add_class("low");
                break;
            case NotificationPriority.NORMAL:
                st.add_class("normal");
                break;
            case NotificationPriority.CRITICAL:
                st.add_class("critical");
                break;
        }
    }

    public override bool draw(Cairo.Context cr)
    {
        Gtk.Allocation alloc;
        get_allocation(out alloc);
        var st = get_style_context();

        st.render_background(cr, alloc.x, alloc.y, alloc.width, alloc.height);
        st.render_frame(cr, alloc.x, alloc.y, alloc.width, alloc.height);

        return true;
    }

    public override void get_preferred_width(out int min, out int natural)
    {
        min = 5;
        natural = 5;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int natural)
    {
        min = 5;
        natural = 5;
    }
}

/**
 * Visual interpretation of a dbus notification
 */
public class Notification : Gtk.Bin
{

    public Notification(string summary, string? body, string? icon_name = "mail-message-new", NotificationPriority priority = NotificationPriority.LOW)
    {
        // main layout
        var layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.get_style_context().add_class("notification");
        add(layout);
        var indicator = new PriorityIndicator(priority);
        indicator.margin_right = 4;
        layout.pack_start(indicator, false, false, 0);

        // side image
        var image = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.DIALOG);
        image.margin_right = 4;
        layout.pack_start(image, false, false, 0);

        // main content.
        var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        layout.pack_start(content, true, true, 0);

        // heading (TODO: Sanitize input!)
        var heading = new Gtk.Label("<big>%s</big>".printf(summary));
        heading.margin_top = 4;
        heading.margin_bottom = 4;
        heading.margin_right = 4;
        heading.use_markup = true;
        content.pack_start(heading, false, false, 0);
        heading.halign = Gtk.Align.START;
        heading.valign = Gtk.Align.START;

        // body if one exists.
        if (body != null) {
            /* Evil - trim the input.. */
            var str = body;
            if (str.length > 100) {
                str = "%s...".printf(str[0:100]);
            }
            var body_label = new Gtk.Label(str);
            content.pack_start(body_label, false, false, 0);
            body_label.halign = Gtk.Align.START;
            body_label.valign = Gtk.Align.START;
            body_label.set_line_wrap(true);
            body_label.margin_bottom = 4;
            body_label.margin_right = 4;
        }

        // close button
        var close = new Gtk.Button.from_icon_name("window-close-symbolic", Gtk.IconSize.MENU);
        close.get_style_context().add_class("image-button");
        close.halign = Gtk.Align.END;
        close.valign = Gtk.Align.START;
        close.relief = Gtk.ReliefStyle.NONE;
        layout.pack_end(close, false, false, 0);
    }

}
