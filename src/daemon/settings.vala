/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2017 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

/**
 * The button layout style as set in budgie
 */
public enum ButtonPosition {
    LEFT = 1 << 0,
    TRADITIONAL = 1 << 1,
}
/**
 * The SettingsManager currently only has a very simple job, and looks for
 * session wide settings changes to respond to
 */
public class SettingsManager
{
    private GLib.Settings? wm_settings = null;
    private GLib.Settings? xoverrides = null;

    /**
     * Create a new xsettings override based on the *Existing* key so that
     * we don't dump any settings like Gdk/ScaleFactor, etc.
     */
    private Variant? new_filtered_xsetting(string button_layout)
    {
        /* These are the two new keys we want */
        var builder = new VariantBuilder(new VariantType("a{sv}"));
        builder.add("{sv}", "Gtk/ShellShowsAppMenu", new Variant.int32(0));
        builder.add("{sv}", "Gtk/DecorationLayout", new Variant.string(button_layout));

        Variant existing_vars = this.xoverrides.get_value("overrides");
        VariantIter it = existing_vars.iterator();
        string? k = null;
        Variant? v = null;
        while (it.next("{sv}", &k, &v)) {
            if (k == "Gtk/ShellShowsAppMenu" || k == "Gtk/DecorationLayout") {
                continue;
            }
            builder.add("{sv}", k, v);
        }
        return builder.end();
    }

    public SettingsManager()
    {
        /* Settings we need to write to */
        xoverrides = new GLib.Settings("org.gnome.settings-daemon.plugins.xsettings");

        wm_settings = new GLib.Settings("com.solus-project.budgie-wm");
        wm_settings.changed.connect(this.on_wm_settings_changed);
        this.on_wm_settings_changed("button-style");
    }

    private void on_wm_settings_changed(string key)
    {
        if (key != "button-style") {
            return;
        }

        ButtonPosition style = (ButtonPosition)wm_settings.get_enum(key);
        this.set_button_style(style);
    }

    /**
     * Set the button layout to one of left or traditional
     */
    void set_button_style(ButtonPosition style)
    {
        Variant? xset = null;
        string? wm_set = null;

        switch (style) {
        case ButtonPosition.LEFT:
            xset = this.new_filtered_xsetting("close,minimize,maximize:menu");
            wm_set = "close,minimize,maximize:appmenu";
            break;
        case ButtonPosition.TRADITIONAL:
        default:
            xset = this.new_filtered_xsetting("menu:minimize,maximize,close");
            wm_set = "appmenu:minimize,maximize,close";
            break;
        }
        this.xoverrides.set_value("overrides", xset);
        this.wm_settings.set_string("button-layout", wm_set);
    }

} /* End class SettingsManager (BudgieSettingsManager) */

} /* End namespace Budgie */
