/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Solus Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class MessageRevealer : Gtk.Revealer
{
    private Gtk.InfoBar info_bar;
    private Gtk.Label message_label;
    private uint expire_id;

    public MessageRevealer()
    {
        Object(visible: false);

        info_bar = new Gtk.InfoBar();
        info_bar.get_style_context().add_class("message-bar");
        add(info_bar);

        message_label = new Gtk.Label("");
        message_label.set_halign(Gtk.Align.START);
        message_label.set_line_wrap(true);
        message_label.set_max_width_chars(35);
        Gtk.Container info_bar_container = info_bar.get_content_area();
        info_bar_container.add(message_label);

        info_bar.response.connect(()=> {
            GLib.Source.remove(expire_id);
            hide_it();
        });
    }

    private void show_it()
    {
        set_no_show_all(false);
        show_all();
        set_reveal_child(true);
    }

    private bool hide_it()
    {
        ulong connection = this.notify["child-revealed"].connect_after(() => {
            set_no_show_all(true);
            hide();
        });
        set_reveal_child(false);
        GLib.Timeout.add(300, ()=> {
            this.disconnect(connection);
            return false;
        });
        return false;
    }

    public void set_content(string message, Gtk.MessageType message_type)
    {
        message_label.set_text(message);
        info_bar.set_message_type(message_type);
        show_it();

        GLib.Source.remove(expire_id);
        expire_id = GLib.Timeout.add(5000, hide_it);
    }
}