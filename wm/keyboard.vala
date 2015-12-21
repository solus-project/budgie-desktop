/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * Copyright (C) GNOME Shell Developers (Heavy inspiration, logic theft)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc {

public static const string DEFAULT_LOCALE = "en_US";
public static const string DEFAULT_LAYOUT = "us";
public static const string DEFAULT_VARIANT = "";

public class KeyboardManager : GLib.Object
{
    public unowned Arc.ArcWM? wm { construct set ; public get; }
    private Gnome.XkbInfo? xkb;
    private string? xkb_layout = null;
    private string? xkb_variant = null;

    public KeyboardManager(Arc.ArcWM? wm)
    {
        Object(wm: wm);

        xkb = new Gnome.XkbInfo();

        update_default();
    }


    void update_default()
    {
        string? type = null;
        string? id = null;
        string? locale = Intl.get_language_names()[0];
        string? display_name = null;
        string? short_name = null;
        string? xkb_layout = null;
        string? xkb_variant = null;

        if (!locale.contains("_")) {
            locale = DEFAULT_LOCALE;
        }

        if (!Gnome.get_input_source_from_locale(locale, out type, out id)) {
            Gnome.get_input_source_from_locale(DEFAULT_LOCALE, out type, out id);
        }

        if(xkb.get_layout_info(id, out display_name, out short_name, out xkb_layout, out xkb_variant)) {
            this.xkb_layout = xkb_layout;
            this.xkb_variant = xkb_variant;
        } else {
            this.xkb_layout = DEFAULT_LAYOUT;
            this.xkb_variant = DEFAULT_VARIANT;
        }
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
