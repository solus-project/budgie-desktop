/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * The meat of the operation
 */
public class RunDialog : Gtk.ApplicationWindow
{

    Settings? settings = null;
    Gtk.CssProvider? css_provider = null;
    private string current_theme_uri;

    public RunDialog(Gtk.Application app)
    {
        Object(application: app);
        set_keep_above(true);
        set_skip_pager_hint(true);
        set_skip_taskbar_hint(true);
        set_resizable(false);
        set_position(Gtk.WindowPosition.CENTER);
        Gdk.Visual? visual = screen.get_rgba_visual();
        if (visual != null) {
            this.set_visual(visual);
        }

        var header = new Gtk.EventBox();
        set_titlebar(header);
        header.get_style_context().remove_class("titlebar");

        var gtksettings = Gtk.Settings.get_default();

        settings = new GLib.Settings("com.solus-project.budgie-panel");
        settings.bind("dark-theme", gtksettings, "gtk-application-prefer-dark-theme", SettingsBindFlags.GET);
        settings.changed.connect(on_settings_changed);

        gtksettings.notify["gtk-theme-name"].connect(on_theme_changed);
        on_settings_changed("builtin-theme");
    }

    /**
     * Handle change to builtin-theme
     */
    void on_settings_changed(string key)
    {
        if (key != "builtin-theme") {
            return;
        }
        if (settings.get_boolean(key)) {
            this.current_theme_uri = Budgie.form_theme_path("theme.css");
        } else {
            this.current_theme_uri = null;
        }

        on_theme_changed();
    }

    /**
     * Set the CSS according to the current theme
     */
    void set_css_from_uri(string? uri)
    {
        var screen = Gdk.Screen.get_default();
        Gtk.CssProvider? new_provider = null;

        if (uri == null) {
            if (this.css_provider != null) {
                Gtk.StyleContext.remove_provider_for_screen(screen, this.css_provider);
                this.css_provider = null;
            }
            return;
        }
    
        try {
            var f = File.new_for_uri(uri);
            new_provider = new Gtk.CssProvider();
            new_provider.load_from_file(f);
        } catch (Error e) {
            warning("Error loading theme: %s", e.message);
            new_provider = null;
            return;
        }

        if (css_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen(screen, css_provider);
            css_provider = null;
        }

        css_provider = new_provider;

        Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    /**
     * Update our theming based on the internal theme setting
     */
    void on_theme_changed()
    {
        var gtksettings = Gtk.Settings.get_default();

        if (gtksettings.gtk_theme_name == "HighContrast") {
            set_css_from_uri(this.current_theme_uri == null ? null : Budgie.form_theme_path("theme_hc.css"));
        } else {
            /* In future we'll actually support custom themes.. */
            set_css_from_uri(this.current_theme_uri);
        }
    }
}

/**
 * GtkApplication for single instance wonderness
 */
public class RunDialogApp : Gtk.Application
{

    private RunDialog? rd = null;

    public RunDialogApp()
    {
        Object(application_id: "com.solus_project.BudgieRunDialog", flags: 0);
    }

    public override void activate()
    {
        if (rd == null) {
            rd = new RunDialog(this);
        }
        rd.present();
    }
}

} /* End namespace */

public static int main(string[] args)
{
    Budgie.please_link_me_libtool_i_have_great_themes();
    Budgie.RunDialogApp rd = new Budgie.RunDialogApp();
    return rd.run(args);
}
