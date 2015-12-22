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

namespace Arc
{

public class NotificationsView : Gtk.Box
{

    public NotificationsView()
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        var img = new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.MENU);
        img.margin_top = 4;
        img.margin_bottom = 4;

        var header = new HeaderWidget("No new notifications", "notification-alert-symbolic", false, null, img);
        header.margin_top = 4;
        header.margin_bottom = 4;

        pack_start(header, false, false, 0);

        show_all();
    }
}

} /* End namespace */

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
