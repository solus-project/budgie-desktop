/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017 Stefan Ric <stefan@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Workspaces {

public class WindowIcon : Gtk.Button
{
    private Wnck.Window window;

    public WindowIcon(Wnck.Window window)
    {
        this.window = window;

        this.set_relief(Gtk.ReliefStyle.NONE);
        this.get_style_context().add_class("workspace-icon-button");
        this.set_tooltip_text(window.get_name());

        Gtk.Image icon = new Gtk.Image.from_pixbuf(window.get_mini_icon());
        icon.set_pixel_size(16);
        this.add(icon);
        icon.show();

        window.name_changed.connect(() => {
            this.set_tooltip_text(window.get_name());
        });

        Gtk.drag_source_set(
            this,
            Gdk.ModifierType.BUTTON1_MASK,
            target_list,
            Gdk.DragAction.MOVE
        );

        Gtk.drag_source_set_icon_pixbuf(this, window.get_icon());

        this.drag_begin.connect(on_drag_begin);
        this.drag_end.connect(on_drag_end);
        this.drag_data_get.connect(on_drag_data_get);

        this.show_all();
    }

    public override bool button_release_event(Gdk.EventButton event) {
        if (event.button != 1) {
            return false;
        }
        if (WorkspacesApplet.wnck_screen.get_active_workspace() == window.get_workspace()) {
            window.activate(event.time);
            return false;
        }
        window.get_workspace().activate(event.time);
        return false;
    }

    private void on_drag_begin(Gtk.Widget widget, Gdk.DragContext context) {
        WorkspacesApplet.dragging = true;
    }

    private void on_drag_end(Gtk.Widget widget, Gdk.DragContext context) {
        WorkspacesApplet.dragging = false;
    }

    public void on_drag_data_get(Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time)
    {
        long window_xid = (long)window.get_xid();
        uchar[] buf;
        convert_long_to_bytes(window_xid, out buf);
        selection_data.set(
            selection_data.get_target(),
            8,
            buf
        );
    }

    private void convert_long_to_bytes(long number, out uchar[] buffer) {
        buffer = new uchar[sizeof(long)];
        for (int i=0; i<sizeof(long); i++) {
            buffer[i] = (uchar)(number & 0xFF);
            number = number >> 8;
        }
    }
}

}