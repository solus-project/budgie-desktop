/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

/**
 * Main entry for the daemon
 */
public static int main(string[] args)
{
    Gtk.init(ref args);
    Budgie.ServiceManager? manager = null;
    Budgie.EndSessionDialog? end_dialog = null;

    manager = new Budgie.ServiceManager();
    end_dialog = new Budgie.EndSessionDialog();

    /* Enter main loop */
    Gtk.main();

    /* Deref - clean */
    manager = null;
    end_dialog = null;
    return 0;
}
