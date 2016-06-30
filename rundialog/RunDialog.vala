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
 * Simple launcher button
 */
public class AppLauncherButton : Gtk.Button
{
    public AppInfo? app_info = null;

    public AppLauncherButton(AppInfo? info)
    {
        this.app_info = info;

        get_style_context().add_class("launcher-button");
        var image = new Gtk.Image.from_gicon(info.get_icon(), Gtk.IconSize.DIALOG);
        image.pixel_size = 48;
        add(image);
        set_relief(Gtk.ReliefStyle.NONE);
        set_hexpand(false);
        set_vexpand(false);
        set_halign(Gtk.Align.START);
        set_valign(Gtk.Align.START);
        set_tooltip_text(info.get_name());
    }
}
/**
 * The meat of the operation
 */
public class RunDialog : Gtk.ApplicationWindow
{

    Settings? settings = null;
    Gtk.CssProvider? css_provider = null;
    private string current_theme_uri;
    Gtk.Revealer bottom_revealer;
    Gtk.FlowBox? app_box;

    string search_text = "";

    public RunDialog(Gtk.Application app)
    {
        Object(application: app);
        set_keep_above(true);
        set_skip_pager_hint(true);
        set_skip_taskbar_hint(true);
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

        get_style_context().add_class("budgie-run-dialog");

        key_release_event.connect(on_key_release);

        var main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);

        /* Main layout, just a hbox with search-as-you-type */
        var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        main_layout.pack_start(hbox, false, false, 0);

        var entry = new Gtk.SearchEntry();
        entry.search_changed.connect(on_search_changed);
        entry.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
        hbox.pack_start(entry, true, true, 0);

        bottom_revealer = new Gtk.Revealer();
        main_layout.pack_start(bottom_revealer, true, true, 0);
        app_box = new Gtk.FlowBox();
        app_box.set_filter_func(this.on_filter);
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);
        scroll.set_size_request(-1, 300);
        scroll.add(app_box);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        bottom_revealer.add(scroll);

        /* Just so I can debug for now */
        bottom_revealer.set_reveal_child(true);

        set_size_request(400, -1);
        main_layout.show_all();
        set_border_width(0);

        Idle.add(build_app_box);
    }

    void on_search_changed(Gtk.SearchEntry? entry)
    {
        this.search_text = entry.get_text().down();
        this.app_box.invalidate_filter();
    }

    /**
     * Filter the list
     */
    bool on_filter(Gtk.FlowBoxChild row)
    {
        var button = row.get_child() as AppLauncherButton;
        var disp_name = button.app_info.get_name().down();

        if (this.search_text in disp_name) {
            return true;
        }
        return false;
    }

    /**
     * Build the app box in the background
     */
    bool build_app_box()
    {
        var apps = AppInfo.get_all();
        apps.foreach(this.add_application);
        app_box.show_all();
        bottom_revealer.set_reveal_child(true);
        return false;
    }

    void add_application(AppInfo? app_info)
    {
        var dinfo = app_info as DesktopAppInfo;
        if (dinfo.get_nodisplay()) {
            return;
        }
        var button = new AppLauncherButton(app_info);
        app_box.add(button);
        button.show_all();
    }

    /**
     * Be a good citizen and pretend to be a dialog.
     */
    bool on_key_release(Gdk.EventKey btn)
    {
        if (btn.keyval == Gdk.Key.Escape) {
            Idle.add(()=> {
                this.application.quit();
                return false;
            });
            return Gdk.EVENT_STOP;
        }
        return Gdk.EVENT_PROPAGATE;
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
