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

namespace Budgie
{

/**
 * Main lifecycle management, handle all the various session and GTK+ bits
 */
public class ServiceManager : GLib.Object
{
    private string? current_theme_uri;
    private Settings? settings;
    private Gtk.CssProvider? css_provider = null;
    /* Keep track of our SessionManager */
    private LibSession.SessionClient? sclient;

    /* On Screen Display */
    Budgie.OSDManager? osd;

    /**
     * Construct a new ServiceManager and initialiase appropriately
     */
    public ServiceManager()
    {
        this.current_theme_uri = Budgie.form_theme_path("theme.css");

        /* Set up dark mode across the desktop */
        settings = new GLib.Settings("com.solus-project.budgie-panel");
        var gtksettings = Gtk.Settings.get_default();
        this.settings.bind("dark-theme", gtksettings, "gtk-application-prefer-dark-theme", SettingsBindFlags.GET);

        settings.changed.connect(on_settings_changed);

        gtksettings.notify["gtk-theme-name"].connect(on_theme_changed);
        on_settings_changed("builtin-theme");

        register_with_session.begin((o,res)=> {
            bool success = register_with_session.end(res);
            if (!success) {
                message("Failed to register with Session manager");
            }
        });
        osd = new Budgie.OSDManager();
        osd.setup_dbus();
    }

    /**
     * Attempt registration with the Session Manager
     */
    private async bool register_with_session()
    {
        try {
            sclient = yield LibSession.register_with_session("budgie-daemon");
        } catch (Error e) {
            return false;
        }

        sclient.QueryEndSession.connect(()=> {
            end_session(false);
        });
        sclient.EndSession.connect(()=> {
            end_session(false);
        });
        sclient.Stop.connect(()=> {
            end_session(true);
        });
        return true;
    }

    /**
     * Properly shutdown when asked to
     */
    private void end_session(bool quit)
    {
        if (quit) {
            Gtk.main_quit();
            return;
        }
        try {
            sclient.EndSessionResponse(true, "");
        } catch (Error e) {
            warning("Unable to respond to session manager! %s", e.message);
        }
    }

    /**
     * Handle a theme change event for all our visible GTK+ components
     */
    void on_theme_changed()
    {
        var gtksettings = Gtk.Settings.get_default();

        if (gtksettings.gtk_theme_name == "HighContrast") {
            set_css_from_uri(this.current_theme_uri == null ? null : Budgie.form_theme_path("theme.css"));
        } else {
            /* In future we'll actually support custom themes.. */
            set_css_from_uri(this.current_theme_uri);
        }
    }

    /**
     * Set the current theme according to the libbudgie-theme CSS
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
     * Update theming based on whether we should use the builtin-theme or not
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
} /* End ServiceManager */


} /* End namespace Budgie */
