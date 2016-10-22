/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2016 Fernando Mussel <fernandomussel91@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public interface ScreenProvider
{
    public abstract Gdk.Screen get_screen();
}

public class WindowMenu
{
    private unowned Wnck.Window window;

    private Gtk.MenuItem close_all_windows_opt;
    private Gtk.MenuItem pinnage;
    private Gtk.MenuItem unpinnage;
    private Gtk.SeparatorMenuItem sep_item;
    private bool requested_pin = false;
    private Wnck.ActionMenu menu;
    private unowned GLib.DesktopAppInfo? app_info = null;
    private unowned Settings settings;
    private unowned ScreenProvider? screen_provider = null;
    private unowned Application? application = null;
    private bool pinning_enabled = false;
    private bool unpinning_enabled = false;

    public WindowMenu(Wnck.Window window, GLib.DesktopAppInfo? app_info,
                      Settings settings, ScreenProvider? screen_provider,
                      Application? application)
    {
        this.window = window;
        this.settings = settings;
        this.screen_provider = screen_provider;
        this.application = application;
        update_app_info(app_info);

        build_application_menu(window, app_info);
        disable_all_pinning_options();
    }

    /**
     * I have no idea why, but this function MUST be called once we no longer
     * need this menu, in order for the destructor of WindowMenu to be called.
     * Perhaps there is a reference cycle between Wnck.Window and ActionMenu.
     */
    public void clear()
    {
        menu.destroy();
    }

    public void update_app_info(GLib.DesktopAppInfo? app_info)
    {
        this.app_info = app_info;
    }

    public void show(uint event_button, uint32 timestamp)
    {
        menu.popup(null, null, null, event_button, timestamp);
    }

    public void enable_pinning_option()
    {
        unpinnage.hide();
        pinnage.show();
        sep_item.show();

        pinning_enabled = true;
        unpinning_enabled = false;
    }

    public void enable_unpinning_option()
    {
        unpinnage.show();
        pinnage.hide();
        sep_item.show();

        pinning_enabled = false;
        unpinning_enabled = true;
    }

    public void disable_all_pinning_options()
    {
        unpinnage.hide();
        pinnage.hide();
        sep_item.hide();

        pinning_enabled = false;
        unpinning_enabled = false;
    }

    private void build_application_menu(Wnck.Window window, GLib.DesktopAppInfo? app_info)
    {
        // Actions menu
        menu = new Wnck.ActionMenu(window);

        var sep = new Gtk.SeparatorMenuItem();
        menu.append(sep);
        sep_item = sep;
        close_all_windows_opt = new Gtk.MenuItem.with_label(_("Close All"));
        pinnage = new Gtk.MenuItem.with_label(_("Pin to panel"));
        unpinnage = new Gtk.MenuItem.with_label(_("Unpin from panel"));
        sep.show();
        close_all_windows_opt.show();
        menu.append(close_all_windows_opt);
        menu.append(pinnage);
        menu.append(unpinnage);

        close_all_windows_opt.activate.connect(()=> {
            application.close_all_windows();
        });
        /* Handle running instance pin/unpin */
        pinnage.activate.connect(()=> {
            assert(pinning_enabled);
            DesktopHelper.set_pinned(settings, app_info, true);
        });

        unpinnage.activate.connect(()=> {
            assert(unpinning_enabled);
            DesktopHelper.set_pinned(settings, app_info, false);
        });

        if (app_info != null) {
            // Desktop app actions =)
            unowned string[] actions = app_info.list_actions();
            if (actions.length == 0) {
                return;
            }
            sep = new Gtk.SeparatorMenuItem();
            menu.append(sep);
            sep.show_all();
            foreach (var action in actions) {
                var display_name = app_info.get_action_name(action);
                var item = new Gtk.MenuItem.with_label(display_name);
                item.set_data("__aname", action);
                item.activate.connect(()=> {
                    string? act = item.get_data("__aname");
                    if (act == null) {
                        return;
                    }
                    // Never know.
                    if (app_info == null) {
                        return;
                    }
                    var launch_context = Gdk.Screen.get_default().get_display().get_app_launch_context();
                    launch_context.set_screen(screen_provider.get_screen());
                    launch_context.set_timestamp(Gdk.CURRENT_TIME);
                    app_info.launch_action(act, launch_context);
                });
                item.show_all();
                menu.append(item);
            }
        }
    }
}
