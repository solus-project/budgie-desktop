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

public class MountItem : ListItem
{
    public signal void send_message(string message_content, Gtk.MessageType message_type);

    public MountItem(GLib.Mount mount, string class)
    {
        item_class = class;
        item_location = mount.get_root().get_uri();

        switch (class) {
            case "device":
                category_name = _("Removable drives");
                break;
            case "network":
                category_name = _("Network folders");
                break;
            default:
                break;
        }

        set_button(mount.get_name(), get_icon(mount.get_symbolic_icon()));

        Gtk.Button unmount_button = new Gtk.Button.from_icon_name("media-eject-symbolic", Gtk.IconSize.MENU);
        unmount_button.get_style_context().add_class("unmount-button");
        unmount_button.set_relief(Gtk.ReliefStyle.NONE);
        unmount_button.set_can_focus(false);

        if (mount.can_eject()) {
            unmount_button.set_tooltip_text(_("Eject"));
        } else {
            unmount_button.set_tooltip_text(_("Unmount"));
        }

        pack_start(unmount_button, false, false, 0);

        unmount_button.clicked.connect(()=> {
            do_unmount(mount);
        });
    }

    /*
     * Figure out if we should eject or unmount
     */
    private void do_unmount(GLib.Mount mount)
    {
        if (mount.can_eject()) {
            mount.eject_with_operation.begin(GLib.MountUnmountFlags.NONE, null, null, (obj, res)=> {
                try {
                    mount.eject_with_operation.end(res);
                } catch (GLib.Error e) {
                    send_message(e.message, Gtk.MessageType.ERROR);
                    message(e.message);
                }
            });
            string safe_remove = _("You can now safely remove");
            string device_name = mount.get_drive().get_name();
            send_message(@"$safe_remove \"$device_name\"", Gtk.MessageType.INFO);
        } else {
            mount.unmount_with_operation.begin(GLib.MountUnmountFlags.NONE, null, null, (obj, res)=> {
                try {
                    mount.unmount_with_operation.end(res);
                } catch (GLib.Error e) {
                    send_message(e.message, Gtk.MessageType.ERROR);
                    message(e.message);
                }
            });
        }
    }
}