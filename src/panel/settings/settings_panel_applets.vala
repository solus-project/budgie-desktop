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

namespace Budgie {

/**
 * AppletsPage contains the applets view for a given panel
 */
public class AppletsPage : Gtk.Box {

    unowned Budgie.Toplevel? toplevel;
    unowned Budgie.DesktopManager? manager = null;

    public AppletsPage(Budgie.DesktopManager? manager, Budgie.Toplevel? toplevel)
    {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        this.manager = manager;
        this.toplevel = toplevel;
    }
} /* End class */

} /* End namespace */
