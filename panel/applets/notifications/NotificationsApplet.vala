/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class NotificationsPlugin : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget()
    {
        return new NotificationsApplet();
    }
}

public class NotificationsApplet : Arc.Applet
{

    Gtk.EventBox? widget;
    Gtk.Image? icon;

    public NotificationsApplet()
    {
        widget = new Gtk.EventBox();
        add(widget);

        icon = new Gtk.Image.from_icon_name("notification-alert-symbolic", Gtk.IconSize.MENU);
        widget.add(icon);

        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        show_all();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(NotificationsPlugin));
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
