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
    Wnck.Screen? screen = null;

    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(Budgie.GETTEXT_PACKAGE, Budgie.LOCALEDIR);
    Intl.bind_textdomain_codeset(Budgie.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Budgie.GETTEXT_PACKAGE);

    manager = new Budgie.ServiceManager();
    end_dialog = new Budgie.EndSessionDialog();

    screen = Wnck.Screen.get_default();
    if (screen != null) {
        screen.force_update();
    }

    /* Enter main loop */
    Gtk.main();

    /* Deref - clean */
    manager = null;
    end_dialog = null;

    Wnck.shutdown();

    return 0;
}
