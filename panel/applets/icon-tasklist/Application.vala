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

public class Application: AttentionStatusListener, IconChangeListener, ScreenProvider
{

    private HashTable<unowned Wnck.Window, ApplicationWindow>? appwindow_map = null;
    // atm, this is the most recently opened window of this application
    private ApplicationWindow? active_appwin = null;

    private WindowListView? window_list = null;
    private IconButton button;
    private unowned WindowManager window_manager;
    private unowned ApplicationManager app_manager;
    private uint windows_requiring_attention_num = 0;
    private GLib.DesktopAppInfo? app_info = null;
    private unowned Settings settings;
    private string? wclass_name = null;
    ulong wclass_id = 0;


    public Application(IconButton btn, WindowManager window_manager,
                       DesktopAppInfo? app_info, Settings settings,
                       ApplicationManager app_manager)
    {

        appwindow_map = new HashTable<unowned Wnck.Window, ApplicationWindow>(direct_hash, direct_equal);
        button = btn;
        this.app_info = app_info;
        this.settings = settings;
        this.app_manager = app_manager;
        button.set_application(this);

        this.window_manager = window_manager;
        window_list = new WindowListView(button, window_manager);
        button.reset();
    }

    public void add_window(Wnck.Window window)
    {
        // create the menu for the new window
        WindowMenu menu = new WindowMenu(window, app_info, settings, this, this);
        ApplicationWindow appwin = new ApplicationWindow(window, menu);

        appwindow_map [window] = appwin;
        window_list.add_window(appwin);
        set_active_window(window);

        // Setup event listeners
        appwin.set_attention_status_listener(this);
        appwin.set_icon_change_listener(this);
        // configures the window minimization animation
        update_window_minimize_animation(window);

        if (get_window_num() == 1) {
            // this is the first window of this application. Configure the
            // button (icon, menu, etc) based on this window's info
            button.configure_button(appwin);
            configure_application(appwin);
        }
    }

    public void remove_window(Wnck.Window window)
    {
        // make sure we have this window
        assert_window_exists(window);
        ApplicationWindow appwin = appwindow_map [window];

        // remove it from the window list popover
        window_list.remove_window(appwin);
        appwindow_map.remove(window);

        if (appwin.needs_attention()) {
            // the window was asking for attention but we closed it. Register
            // end of attetion request
            attention_requested_ended();
        }

        if (get_window_num() == 0) {
            // the application has no more windows opened. Reset the associated
            // button. This is specially important for Pinned Applications
            button.reset();
            active_appwin = null;
        } else if (appwin == active_appwin) {
            // We are removing the "active window". Change the active_appwin
            // to the second most recently opened window
            active_appwin = null;
            set_active_window(get_first_window());
        }
    }

    public void close_all_windows()
    {
        // get the list of opened windows
        var appwin_keys = appwindow_map.get_keys();

        // ask the window manager to close each one of them
        appwin_keys.foreach((window)=> {
            window_manager.close_window(window);
        });
    }

    /**
     * Replace the button associated with application for a new one.
     */
    public void replace_button(IconButton btn)
    {
        button = btn;
        // give a reference to ourselves to the new button
        button.set_application(this);
        // make the new button the owner of the window list popover
        window_list.replace_owner(button);

        if (get_window_num() > 0) {
            // we have at least one window. So configure the new button according
            // to one of our opened windows
            button.configure_button(active_appwin);
        }
    }

    public uint get_window_num()
    {
        return appwindow_map.size();
    }

    public bool has_window_opened()
    {
        return get_window_num() > 0;
    }

    public Gtk.Popover get_window_list_popover()
    {
        return window_list.get_popover();
    }

    public string? get_id()
    {
        return (app_info == null) ? null : app_info.get_id();
    }

    public GLib.DesktopAppInfo? get_info()
    {
        return app_info;
    }

    /**
     * Returns a reference to the most recently opened window or null if there
     * is no window opened
     */
    public Wnck.Window? get_active_window()
    {
        Wnck.Window? window = null;
        if (active_appwin != null) {
            window = active_appwin.get_window();
        }
        return window;
    }

    public void set_active_window(Wnck.Window window)
    {
        var new_active_appwin = appwindow_map [window];
        // prevent unnecessary work if the new active window is the same as before
        if (new_active_appwin != active_appwin) {
            active_appwin = new_active_appwin;
            button.update_icon(window);
        }
    }

    public void show_active_window_menu(uint event_button, uint32 timestamp)
    {
        if (active_appwin != null) {
            var menu = active_appwin.get_menu();

            if (app_info == null) {
                // we can not pin or unpin an application that we do not have
                // DesktopAppInfo about
                menu.disable_all_pinning_options();
            } else if (button is PinnedIconButton) {
                // Application is already pinned. Enable the unpinning option
                menu.enable_unpinning_option();
            } else {
                menu.enable_pinning_option();
            }
            menu.show(event_button, timestamp);
        }
    }


    public IconButton get_button()
    {
        return button;
    }

    /**
     * Get any window from the HashTable
     */
    private Wnck.Window? get_first_window()
    {
        var iter = HashTableIter<unowned Wnck.Window, ApplicationWindow>(appwindow_map);
        Wnck.Window? win = null;

        iter.next(out win, null);
        return win;
    }

    /**
     * Configures the window's minimize animation based on the application's
     * button position in the tasklist
     */
    private void update_window_minimize_animation(Wnck.Window window)
    {
        int x, y;
        button.get_coordinates(out x, out y);
        var alloc = button.get_allocation();

        window.set_icon_geometry(x, y, alloc.width, alloc.height);
    }

    /**
     * When the application's button changes place this function is called
     * to update the minimize animation of all windows registered
     */
    public void button_allocation_updated()
    {
        var iter = HashTableIter<Wnck.Window, ApplicationWindow>(appwindow_map);
        Wnck.Window? window = null;

        // Updates the minimize animation of all the windows
        while (iter.next(out window, null)) {
            update_window_minimize_animation(window);
        }
    }

    /**
     * This function is part of the AttentionStatusListener interface. It is
     * called by ApplicationWindow when a Window begins or ends an attention
     * request
     */
    public void attention_status_changed(ApplicationWindow appwin, bool needs_attention)
    {
        if (needs_attention) {
            // update the # of windows requesting attention
            ++windows_requiring_attention_num;
            // forward change to application button
            button.begin_attention_request();
            // forward change to window list item associated with the requesting
            // window
            window_list.begin_attention_request(appwin);
        } else {
            window_list.end_attention_request(appwin);
            attention_requested_ended();
        }
    }

    /**
     * Function is part of the ScreenProvider interface. By making the application
     * object the provider, we do not need to update the provider reference
     * in all window menus when the button changes, e.g. during pinning and
     * unpinning
     */
    public Gdk.Screen get_screen()
    {
        return button.get_screen();
    }

    /**
     * Function is part of the IconChangeListener interface. Update the button's
     * icon if the window whose icon changed is the "active" one
     */
    public void icon_changed(ApplicationWindow appwin)
    {
        if (appwin == active_appwin) {
            button.update_icon(appwin.get_window());
        }
    }

    private void attention_requested_ended()
    {
        --windows_requiring_attention_num;
        // Only forward to button the end of the attention request if no more
        // windows are requesting it
        if (windows_requiring_attention_num == 0) {
            button.end_attention_request();
        }
    }

    private void assert_window_exists(Wnck.Window window)
    {
        assert(appwindow_map.contains(window));
    }

    /**
     * Performs general application-wide configurations that are only possible
     * after the first window is registered
     */
    private void configure_application(ApplicationWindow first_app_win)
    {
        var window = first_app_win.get_window();
        wclass_name = window.get_class_instance_name();

        /* No app info, no class name, probably spotify */
        if (app_info == null && wclass_name == null) {
            // setup callback for window class change
            wclass_id = window.class_changed.connect((win)=> {
                string nclass_name = win.get_class_instance_name();
                if (nclass_name != null && wclass_name == null) {
                    // unregister callback
                    win.disconnect(wclass_id);
                    wclass_id = 0;
                    // update window app info
                    wclass_name = nclass_name;
                    app_info = window_manager.query_window(win);

                    if (app_info != null && app_manager.app_info_update(win, app_info)) {
                        // we have managed to get info on the application (Spotify) and
                        // the application manager returned true for app_info_update
                        // call, meaning that it will continue to use this application
                        // object instance. So we need to do some housekeeping and
                        // re-configure things based on app_info
                        WindowMenu menu = new WindowMenu(win, app_info, settings, this, this);
                        appwindow_map [win].set_menu(menu);
                        // reconfigure button now using app_info
                        button.configure_button(appwindow_map [win]);
                    }
                }
            });
        }
    }

}
