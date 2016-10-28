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
public class AppLauncherButton : Gtk.Box
{
    public AppInfo? app_info = null;

    public AppLauncherButton(AppInfo? info)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.app_info = info;

        get_style_context().add_class("launcher-button");
        var image = new Gtk.Image.from_gicon(info.get_icon(), Gtk.IconSize.DIALOG);
        image.pixel_size = 48;
        image.set_margin_start(8);
        pack_start(image, false, false, 0);

        var nom = Markup.escape_text(info.get_name());
        var sdesc = info.get_description();
        if (sdesc == null) {
            sdesc = "";
        }
        var desc = Markup.escape_text(sdesc);
        var label = new Gtk.Label("<big>%s</big>\n<small>%s</small>".printf(nom, desc));
        label.get_style_context().add_class("dim-label");
        label.set_line_wrap(true);
        label.set_property("xalign", 0.0);
        label.use_markup = true;
        label.set_margin_start(12);
        label.set_max_width_chars(60);
        label.set_halign(Gtk.Align.START);
        pack_start(label, false, false, 0);

        set_hexpand(false);
        set_vexpand(false);
        set_halign(Gtk.Align.START);
        set_valign(Gtk.Align.START);
        set_tooltip_text(info.get_name());
        set_margin_top(3);
        set_margin_bottom(3);
    }
}
/**
 * The meat of the operation
 */
public class RunDialog : Gtk.ApplicationWindow
{

    Gtk.Revealer bottom_revealer;
    Gtk.ListBox? app_box;
    Gtk.SearchEntry entry;
    Budgie.ThemeManager theme_manager;

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

        /* Handle all theme management */
        this.theme_manager = new Budgie.ThemeManager();

        var header = new Gtk.EventBox();
        set_titlebar(header);
        header.get_style_context().remove_class("titlebar");

        get_style_context().add_class("budgie-run-dialog");

        key_release_event.connect(on_key_release);

        var main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);

        /* Main layout, just a hbox with search-as-you-type */
        var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        main_layout.pack_start(hbox, false, false, 0);

        this.entry = new Gtk.SearchEntry();
        entry.changed.connect(on_search_changed);
        entry.activate.connect(on_search_activate);
        entry.get_style_context().set_junction_sides(Gtk.JunctionSides.BOTTOM);
        hbox.pack_start(entry, true, true, 0);

        bottom_revealer = new Gtk.Revealer();
        main_layout.pack_start(bottom_revealer, true, true, 0);
        app_box = new Gtk.ListBox();
        app_box.set_selection_mode(Gtk.SelectionMode.SINGLE);
        app_box.set_activate_on_single_click(true);
        app_box.row_activated.connect(on_row_activate);
        app_box.set_filter_func(this.on_filter);
        var scroll = new Gtk.ScrolledWindow(null, null);
        scroll.get_style_context().set_junction_sides(Gtk.JunctionSides.TOP);
        scroll.set_size_request(-1, 300);
        scroll.add(app_box);
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        bottom_revealer.add(scroll);

        /* Just so I can debug for now */
        bottom_revealer.set_reveal_child(false);

        this.build_app_box();

        set_size_request(240, -1);
        main_layout.show_all();
        set_border_width(0);
        set_resizable(false);

        focus_out_event.connect(()=> {
            this.application.quit();
            return Gdk.EVENT_STOP;
        });
    }

    /**
     * Handle click/<enter> activation on the main list
     */
    void on_row_activate(Gtk.ListBoxRow row)
    {
        var child = (row as Gtk.Bin).get_child() as AppLauncherButton;
        this.launch_button(child);
    }

    /**
     * Handle <enter> activation on the search
     */
    void on_search_activate()
    {
        AppLauncherButton? act = null;
        foreach (var row in app_box.get_children()) {
            if (row.get_visible() && row.get_child_visible()) {
                act = (row as Gtk.Bin).get_child() as AppLauncherButton;
                break;
            }
        }
        if (act != null) {
            this.launch_button(act);
        }
    }

    /**
     * Launch the given preconfigured button
     */
    void launch_button(AppLauncherButton button)
    {
        try {
            var dinfo = button.app_info as DesktopAppInfo;
            dinfo.launch_uris_as_manager(null, null,
                SpawnFlags.SEARCH_PATH,
                null, null);
            this.hide();
            /* Allow dbus activation to happen.. which we'll never be told about. Woo. */
            Timeout.add(500, ()=> {
                this.destroy();
                return false;
            });
        } catch (Error e) {
            message("Error: %s\n", e.message);
            this.application.quit();
        }
    }

    void on_search_changed()
    {
        this.search_text = entry.get_text().down();
        this.app_box.invalidate_filter();
        Gtk.Widget? active_row = null;

        foreach (var row in app_box.get_children()) {
            if (row.get_visible() && row.get_child_visible()) {
                active_row = row;
                break;
            }
        }

        if (active_row == null) {
            bottom_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_UP);
            bottom_revealer.set_reveal_child(false);
        } else {
            bottom_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
            bottom_revealer.set_reveal_child(true);
            app_box.select_row(active_row as Gtk.ListBoxRow);
        }
    }

    /**
     * Filter the list
     */
    bool on_filter(Gtk.ListBoxRow row)
    {
        var button = row.get_child() as AppLauncherButton;

        if (search_text == "") {
            return false;
        }

        string? app_name, desc, name, exec;

        /* Ported across from budgie menu */
        app_name = button.app_info.get_display_name();
        if (app_name != null) {
            app_name = app_name.down();
        } else {
            app_name = "";
        }
        desc = button.app_info.get_description();
        if (desc != null) {
            desc = desc.down();
        } else {
            desc = "";
        }
        name = button.app_info.get_name();
        if (name != null) {
            name = name.down();
        } else {
            name = "";
        };
        exec = button.app_info.get_executable();
        if (exec != null) {
            exec = exec.down();
        } else {
            exec = "";
        }
        return (search_text in app_name || search_text in desc ||
                search_text in name || search_text in exec);
    }

    /**
     * Build the app box in the background
     */
    void build_app_box()
    {
        var apps = AppInfo.get_all();
        apps.foreach(this.add_application);
        app_box.show_all();
        this.entry.set_text("");
    }

    void add_application(AppInfo? app_info)
    {
        if (!app_info.should_show()) {
            return;
        }
        var dinfo = app_info as DesktopAppInfo;
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
    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(Budgie.GETTEXT_PACKAGE, Budgie.LOCALEDIR);
    Intl.bind_textdomain_codeset(Budgie.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Budgie.GETTEXT_PACKAGE);

    Budgie.RunDialogApp rd = new Budgie.RunDialogApp();
    return rd.run(args);
}
