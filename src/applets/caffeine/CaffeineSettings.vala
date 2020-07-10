/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2018-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Caffeine
{

[GtkTemplate (ui = "/com/solus-project/caffeine/settings.ui")]
public class AppletSettings : Gtk.Grid
{
    private Settings? settings = null;
    private Settings? wm_settings = null;

    [GtkChild]
    private Gtk.Switch? notify_switch;

    [GtkChild]
    private Gtk.Switch? brightness_switch;

    [GtkChild]
    private Gtk.SpinButton? brightness_level;

    public AppletSettings(Settings? settings)
    {
        Object();
        this.settings = settings;
        this.wm_settings = new Settings("com.solus-project.budgie-wm");

        // Bind settings to widget value
        wm_settings.bind("caffeine-mode-notification", notify_switch, "active", SettingsBindFlags.DEFAULT);
        wm_settings.bind("caffeine-mode-toggle-brightness", brightness_switch, "active", SettingsBindFlags.DEFAULT);
        wm_settings.bind("caffeine-mode-screen-brightness", brightness_level, "value", SettingsBindFlags.DEFAULT);
    }
}
} //End namespace

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
