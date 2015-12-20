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


public static int main(string[] args)
{
    unowned OptionContext? ctx = null;

    ctx = Meta.get_option_context();

    if (!Gtk.init_check(ref args)) {
        warning("GTK+ functionality not available");
        Arc.ArcWM.gtk_available = false;
    }

    try {
        if (!ctx.parse(ref args)) {
            return Meta.ExitCode.ERROR;
        }
    } catch (OptionError e) {
        message("Unknown option: %s", e.message);
        return Meta.ExitCode.ERROR;
    }

    /* Set plugin type here */
    Meta.Plugin.manager_set_plugin_type(typeof(Arc.ArcWM));
    Meta.set_gnome_wm_keybindings("Mutter,GNOME Shell");
    Meta.set_wm_name("Mutter(Arc)");

    Environment.set_variable("NO_GAIL", "1", true);
    Environment.set_variable("NO_AT_BRIDGE", "1", true);

    Meta.init();

    Meta.register_with_session();

    return Meta.run();
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
