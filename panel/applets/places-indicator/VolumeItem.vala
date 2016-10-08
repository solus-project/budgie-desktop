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

public class VolumeItem : ListItem
{
    public signal void send_message(string message_content, Gtk.MessageType message_type);

    public VolumeItem(GLib.Volume volume)
    {
        item_class = volume.get_identifier("class");

        switch (item_class) {
            case "device":
                category_name = _("Removable drives");
                break;
            case "network":
                category_name = _("Network folders");
                break;
            default:
                break;
        }

        set_button(volume.get_name(), get_icon(volume.get_symbolic_icon()));

        GLib.MountOperation operation = new GLib.MountOperation();
        operation.set_password_save(GLib.PasswordSave.FOR_SESSION);

        name_button.set_tooltip_text(_("Mount and open \"%s\"".printf(volume.get_name())));
        name_button.clicked.connect(()=> {
            volume.mount.begin(GLib.MountMountFlags.NONE, operation, null, (obj, res)=>{
                try {
                    volume.mount.end(res);
                    open_directory(volume.get_mount().get_root().get_uri());
                } catch (GLib.Error e) {
                    send_message(e.message, Gtk.MessageType.ERROR);
                    warning(e.message);
                }
            });
        });
    }
}