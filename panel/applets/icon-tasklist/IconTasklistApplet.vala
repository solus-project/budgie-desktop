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

public interface ApplicationManager
{
    public abstract bool app_info_update(Wnck.Window window, GLib.DesktopAppInfo app_info);
}

/**
 * Attempt to match startup notification IDs
 */
public static bool startupid_match(string id1, string id2)
{
    /* Simple. If id1 == id2, or id1(WINID+1) == id2 */
    if (id1 == id2) {
        return true;
    }
    string[] spluts = id1.split("_");
    string[] splits = spluts[0].split("-");
    int winid = int.parse(splits[splits.length-1])+1;
    string id3 = "%s-%d_%s".printf(string.joinv("-", splits[0:splits.length-1]), winid, string.joinv("_", spluts[1:spluts.length]));

    return (id2 == id3);
}

public class IconTasklist : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new IconTasklistApplet(uuid);
    }
}

/**
 * Trivial helper for IconTasklist - i.e. desktop lookups
 */
public class DesktopHelper : Object
{
    public static const Gtk.TargetEntry[] targets = {
        { "application/x-icon-tasklist-launcher-id", 0, 0 }
    };

    public static void set_pinned(Settings? settings, DesktopAppInfo app_info, bool pinned)
    {
        string[] launchers = settings.get_strv("pinned-launchers");
        if (pinned) {
            if (app_info.get_id() in launchers) {
                return;
            }
            launchers += app_info.get_id();
            settings.set_strv("pinned-launchers", launchers);
            return;
        }
        // Unpin a launcher
        string[] new_launchers = {};
        bool did_remove = false;
        foreach (var launcher in launchers) {
            if (launcher != app_info.get_id()) {
                new_launchers += launcher;
            } else {
                did_remove = true;
            }
        }
        // Go ahead and set
        if (did_remove) {
            settings.set_strv("pinned-launchers", new_launchers);
        }
    }
}

public class IconTasklistApplet : Budgie.Applet, ButtonManager, WindowManager, ApplicationManager
{

    protected Gtk.Box widget;
    protected Gtk.Box main_layout;
    protected Gtk.Box pinned;

    protected Wnck.Screen screen;

    protected HashTable<string?,Application?> opened_apps;
    protected HashTable<Wnck.Window,Application?> win_to_app_map;
    protected HashTable<string?,Application?> pinned_apps;
    // application objects waitting to be removed
    protected Queue<Application?> tmp_apps;

    protected int icon_size = 32;
    private Settings settings;
    protected string kPinningSettingsKey = "pinned-launchers";

    protected Gdk.AppLaunchContext context;
    protected AppSystem? helper;

    private IconButton? active_button = null;

    public string uuid { public set ; public get ; }
    private Budgie.PopoverManager? popover_manager = null;



    public IconTasklistApplet(string uuid)
    {
        Object(uuid: uuid);

        this.context = Gdk.Screen.get_default().get_display().get_app_launch_context();

        settings_schema = "com.solus-project.icon-tasklist";
        settings_prefix = "/com/solus-project/budgie-panel/instance/icon-tasklist";

        helper = new AppSystem();

        // Easy mapping :)
        opened_apps = new HashTable<string?, Application?>(str_hash, str_equal);
        win_to_app_map = new HashTable<Wnck.Window, Application>(direct_hash, direct_equal);
        pinned_apps = new HashTable<string?,Application?>(str_hash, str_equal);
        tmp_apps = new Queue<Application?>();


        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        pinned = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        pinned.margin_end = 14;
        pinned.get_style_context().add_class("pinned");
        main_layout.pack_start(pinned, false, false, 0);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        widget.get_style_context().add_class("unpinned");
        main_layout.pack_start(widget, false, false, 0);

        add(main_layout);
        show_all();

        settings = this.get_applet_settings(uuid);
        settings.changed.connect(on_settings_change);

        on_settings_change("pinned-launchers");

        // Init wnck
        screen = Wnck.Screen.get_default();
        screen.window_opened.connect(window_opened);
        screen.window_closed.connect(window_closed);
        screen.active_window_changed.connect(active_window_changed);

        panel_size_changed.connect(on_panel_size_changed);

        Gtk.drag_dest_set(pinned, Gtk.DestDefaults.ALL, DesktopHelper.targets, Gdk.DragAction.MOVE);

        pinned.drag_data_received.connect(on_drag_data_received);

        get_style_context().add_class("icon-tasklist");

        show_all();
    }

    void set_icons_size()
    {
        unowned Wnck.Window? btn_key = null;
        unowned string? str_key = null;
        unowned Application? app = null;
        unowned Application? pin_app = null;

        icon_size = small_icons;
        Wnck.set_default_icon_size(icon_size);

        Idle.add(()=> {
            var iter = HashTableIter<Wnck.Window?,Application?>(win_to_app_map);
            while (iter.next(out btn_key, out app)) {
                IconButton btn = app.get_button();
                btn.panel_size = panel_size;
                btn.update_icon_size(icon_size);
            }

            var iter2 = HashTableIter<string?,Application?>(pinned_apps);
            while (iter2.next(out str_key, out pin_app)) {
                var btn = pin_app.get_button();
                btn.panel_size = panel_size;
                btn.update_icon_size(icon_size);
            }
            return false;
        });
        queue_resize();
        queue_draw();
    }

    int small_icons = 32;
    int panel_size = 10;

    void on_panel_size_changed(int panel, int icon, int small_icon)
    {
        this.small_icons = small_icon;
        this.panel_size = panel;

        set_icons_size();
    }

    private void move_launcher(string app_id, int position)
    {
        string[] launchers = settings.get_strv("pinned-launchers");

        if(position > launchers.length || position < 0) {
            return;
        }

        // Create a new list for holding the launchers
        var temp_launchers = new List<string>();

        var old_index = 0;
        var new_position = position;

        for(var i = 0; i < launchers.length; i++) {

            // Add launcher to the next position if it is not the one that has to be moved
            if(launchers[i] != app_id) {
                temp_launchers.append(launchers[i]);
            } else {
                old_index = i;
            }
        }

        // Check if the indexes changed after removing the launcher from the list
        if(new_position > old_index) {
            new_position--;
        }

        temp_launchers.insert(app_id, new_position);

        // Convert launchers list back to array
        for(var i = 0; i < launchers.length; i++) {
            launchers[i] = temp_launchers.nth_data(i);
        }

        // Save pinned launchers
        settings.set_strv("pinned-launchers", launchers);
    }

    private void on_drag_data_received(Gtk.Widget widget, Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint item, uint time)
    {
        string[] launchers = settings.get_strv("pinned-launchers");
        Gtk.Allocation main_layout_allocation;

        // Get allocation of main layout
        main_layout.get_allocation(out main_layout_allocation);

        if(item != 0) {
            message("Invalid target type");
            return;
        }

        // id of app that is currently being dragged
        var app_id = (string) selection_data.get_data();

        // Iterate through launchers
        for(var i = 0; i < launchers.length; i++) {

            Gtk.Allocation alloc;

            var launcher = launchers[i];

            (pinned_apps[launchers[i]].get_button().get_parent() as ButtonWrapper).get_allocation(out alloc);

            if(x <= (alloc.x + (alloc.width / 2) - main_layout_allocation.x)) {

                // Check if launcher is being moved left to the same position as it currently is
                if(launchers[i] == app_id) {
                    break;
                }

                // Check if launcher is being moved right to the same position as it currently is
                if(i > 0 && launchers[i - 1] == app_id) {
                    break;
                }

                move_launcher(app_id, i);

                break;
            }

            // Move launcher to the very end
            if(i == launchers.length - 1) {

                // Check if launcher is already at the end
                if(launchers[i] == app_id) {
                    break;
                }

                move_launcher(app_id, launchers.length);
            }
        }

        Gtk.drag_finish(context, true, true, time);
    }
    public override void update_popovers(Budgie.PopoverManager? new_manager)
    {
        this.popover_manager = new_manager;
        reregister_applications_window_list();
    }

    /**
     * Re-register the Window List popovers of all opened Applications
     */
    private void reregister_applications_window_list()
    {
        Application? app;
        // this map contains all openned apps, even those without an app_id
        var iter = HashTableIter<Wnck.Window, Application?>(win_to_app_map);

        while (iter.next(null, out app)) {
            popover_manager.register_popover(app.get_button(), app.get_window_list_popover());
        }
    }

    private void unregister_window_list(IconButton btn, Gtk.Popover popover)
    {
        // Make sure we hide the popover before we unregister it
        if (popover.get_visible()) {
            popover.hide();
        }

        popover_manager.unregister_popover(btn);
    }


    private Application? get_pinned_application_by_startup_id(string startup_id)
    {

      PinnedIconButton? pbtn = null;
      Application? pin_app;
      var iter = HashTableIter<string?,Application?>(pinned_apps);

      // iterate through the map of pinned buttons looking for the one
      // matching startup_id
      while (iter.next(null, out pin_app)) {
          pbtn = (PinnedIconButton) pin_app.get_button();
          if (pbtn.id != null && startupid_match(pbtn.id, startup_id)) {
              return pin_app;
          }
      }

      // no button associated with startup_id
      return null;
    }

    private bool is_application_pinned(Application app)
    {
        var app_id = app.get_id ();
        return (app_id != null && pinned_apps.contains(app_id));
    }

    private Application? get_pinned_application_by_id(string app_id)
    {
        return pinned_apps.contains (app_id) ? pinned_apps [app_id] : null;
    }

    private Application? get_pinned_application(string? startup_id, string? app_id)
    {
        Application? app = null;
        if (startup_id != null) {
            app = get_pinned_application_by_startup_id(startup_id);
        }
        // could not get by startup_id. Try using the app_id
        if (app == null && app_id != null) {
            app = get_pinned_application_by_id(app_id);
        }

        return app;
    }

    void register_window_opened(string? app_id, Wnck.Window window, Application app)
    {
        // associate the window with its parent application
        win_to_app_map [window] = app;
        if (app_id != null && !opened_apps.contains(app_id)) {
            // first window of application. Application not registered as opened yet
            opened_apps [app_id] = app;
            // register the window list of the new application
            popover_manager.register_popover(app.get_button(), app.get_window_list_popover());
        }
    }

    void register_window_closed(string? app_id, Wnck.Window window, Application app)
    {
        bool is_last_win = (app.get_window_num() == 0);

        if (app_id != null && is_last_win) {
            // this was the last opened window of app_id. "Register" application
            // as closed
            opened_apps.remove(app_id);

            // we just closed the last window of an application. Make sure we also
            // hide its window list popover, if it is visible
            var popover = app.get_window_list_popover();
            if (popover.get_visible()) {
                popover.hide();
            }
            // unregister window list
            unregister_window_list(app.get_button(), app.get_window_list_popover());
        }
        // unregister window
        win_to_app_map.remove(window);
    }

    /**
     * Immense hack to make spotify play nicely. Returns true if we are going
     * to keep using the same Application Object or false otherwise.
     */
    public bool app_info_update(Wnck.Window window, GLib.DesktopAppInfo app_info)
    {
        // this is a hack for properly registering spotify as opened
        string app_id = app_info.get_id();
        Application? old_app = null;

        if (opened_apps.contains(app_id)) {
            old_app = opened_apps [app_id];
        } else if (pinned_apps.contains(app_id)) {
            old_app = pinned_apps [app_id];
        }

        if (old_app != null) {
            // application was either pinned or already opened. Either way,
            // we are going to use the old application object
            var new_app = win_to_app_map [window];
            tmp_apps.push_tail(new_app);
            new_app.remove_window(window);

            if (new_app.get_button() == active_button) {
                // the current window is the active one and since we are
                // handing it over to the old_app instance, we should make old_app's
                // button the active one
                replace_active_button(old_app.get_button());
            }
            kill_button(new_app.get_button());

            // Assign window to the older application
            old_app.add_window(window);
            register_window_opened(app_id, window, old_app);

            Idle.add(() => {
                // new_app is calling this function and since we removed it from
                // the win_to_app_map HashTable, as soon as we go out of scope
                // and return to new_app callee function, it will have gotten
                // deallocated causing a segmentation fault. Thus, we hold a
                // strong reference to it temporarily and shortly after we clear
                // it, allowing new_app to be deallocated.
                tmp_apps.clear();
                return false;
            });

            // let callee know we are using a different application object
            return false;
        } else {
            // application was not registered yet. Now with the app_id, register it
            var app = win_to_app_map [window];
            // re-register the application
            register_window_opened(app_id, window, app);
            // we continue to use the same application object
            return true;
        }
    }

    protected void window_opened(Wnck.Window window)
    {
        // doesn't go on our list
        if (window.is_skip_tasklist()) {
            return;
        }
        string? launch_id = null;
        Application? application = null;

        if (window.get_application() != null) {
            launch_id = window.get_application().get_startup_id();
        }
        var pinfo = helper.query_window(window);
        string? app_id = (pinfo != null) ? pinfo.get_id() : null;

        // check if the app is already opened or if it is a pinned app. Either
        // way we do not need add another button to the tray
        if (app_id != null && opened_apps.contains(app_id)) {
            application = opened_apps [app_id];
            application.add_window(window);
        } else if ((application = get_pinned_application(launch_id, app_id)) != null) {
            application.add_window(window);
        } else {
            // Fallback to new button. Either the app is not pinned and was not opened
            // or it is an app without id
            var btn = new IconButton(settings, icon_size, this.helper, panel_size, this, this);
            application = new Application(btn, this, pinfo, settings, this);
            application.add_window(window);
            var button_wrap = new ButtonWrapper(btn);

            // add new button to tray and animate is appearence
            widget.pack_start(button_wrap, false, false, 0);
            (btn.get_parent() as Gtk.Revealer).set_reveal_child(true);
        }

        // register new window as opened
        register_window_opened(app_id, window, application);
    }

    protected void window_closed(Wnck.Window window)
    {
        IconButton? btn = null;
        Application? app = null;
        if (!win_to_app_map.contains(window)) {
            return;
        }
        app = win_to_app_map [window];
        btn = app.get_button();
        // unregister the window from application
        app.remove_window(window);
        // remove the registry of the window and if this is the last window of
        // this app, also register the app as closed
        register_window_closed(app.get_id(), window, app);

        if (app.get_window_num() == 0 && !is_application_pinned(app)) {
            // last window of non-pinned app was closed. Remove its button
            kill_button(btn);
        }
    }

    /**
     * Just update the active state on the buttons
     */
    protected void active_window_changed(Wnck.Window? previous_window)
    {
        IconButton? btn;
        Wnck.Window? new_active;

        new_active = screen.get_active_window();
        if (new_active != null && win_to_app_map.contains(new_active)) {
            // get window associated with new active window
            var app = win_to_app_map [new_active];
            btn = app.get_button();
            // make it the new active button
            replace_active_button(btn);
            // make the new active window the current window of the application
            app.set_active_window(new_active);

            if (!btn.get_realized()) {
                btn.realize();
                btn.queue_resize();
            }
        } else {
            // there is no new active window or new window does not have a button
            clear_active_button();
        }
        queue_draw();
    }

    /**
     * Correctly removes a button. Disconnects all the callbacks registered
     * in the button to prevent one of the to be called after the button is
     * not suppose to exist anymore, e.g. size_allocation.
     */
    private void kill_button(IconButton btn)
    {
        (btn.get_parent() as ButtonWrapper).gracefully_die();
        btn.reset_callbacks();
    }

    private void replace_active_button(IconButton btn)
    {
        clear_active_button();
        active_button = btn;
        active_button.set_active(true);
    }

    private void clear_active_button()
    {
        if (active_button != null) {
            var tmp = active_button;
            // just in case it calls toggle before assigning null
            active_button = null;
            tmp.set_active(false);
        }
    }

    /**
     * Tells btn if it is current active button
     */
    public bool can_become_active(IconButton btn){
        return (btn == active_button);
    }

    /**
     * Display the Window list of a given button
     */
    public void toggle_window_list(IconButton btn, Gtk.Popover popover)
    {
        if (popover.get_visible()) {
            popover.hide();
        } else {
            popover_manager.show_popover(btn);
        }
    }

    public void toggle_window(Wnck.Window window)
    {
        var timestamp = Gtk.get_current_event_time();
        if (window.is_minimized()) {
            window.unminimize(timestamp);
            window.activate(timestamp);
        } else {
            if (window.is_active()) {
                window.minimize();
            } else {
                window.activate(timestamp);
            }
        }
    }

    public void close_window(Wnck.Window win)
    {
        var timestamp = Gtk.get_current_event_time();
        win.close(timestamp);
    }

    public DesktopAppInfo? query_window(Wnck.Window window)
    {
        return helper.query_window(window);
    }

    protected void replace_application_button(Application app, IconButton new_btn)
    {

        IconButton old_btn = app.get_button();
        // Unregister popover associated with the old button
        unregister_window_list(old_btn, app.get_window_list_popover());
        // if old button is the active one, replace it by the new
        if (old_btn == active_button) {
            replace_active_button(new_btn);
        }
        // make the actual button replacement
        app.replace_button(new_btn);
        // update button popover
        popover_manager.register_popover(new_btn, app.get_window_list_popover());
    }

    protected void insert_new_pinned_buttons(string [] files)
    {

        /* We don't actually remove anything >_> */
        foreach (string desktopfile in files) {
            /* Ensure we don't have this fella already. */
            if (pinned_apps.contains(desktopfile)) {
                continue;
            }
            var info = new DesktopAppInfo(desktopfile);
            if (info == null) {
                continue;
            }
            var button = new PinnedIconButton(settings, icon_size, ref this.context, this.helper, panel_size, this, this);
            var button_wrap = new ButtonWrapper(button);
            Application? pin_app = null;

            if (opened_apps.contains(info.get_id())) {
                // application being pinned is already opened
                pin_app = opened_apps [info.get_id()];
                var btn = pin_app.get_button();

                // replace application's pinned button by a non-pinned version
                replace_application_button(pin_app, button);
                // destroy old one
                kill_button(btn);
            } else {
                // there was no application opened with such id. Create a new
                // application object
                pin_app = new Application(button, this, info, settings, this);
            }
            // register application as pinned
            pinned_apps[desktopfile] = pin_app;

            // add new pinned button to the tray
            pinned.pack_start(button_wrap, false, false, 0);
            (button.get_parent() as Gtk.Revealer).set_reveal_child(true);
        }
    }

    private void remove_unpinned_buttons(string [] files)
    {
        string[] removals = {};
        /* Conversely, remove ones which have been unset. */
        var iter = HashTableIter<string?,Application?>(pinned_apps);
        string? key_name;
        PinnedIconButton? btn;
        Application? app;
        while (iter.next(out key_name, out app)) {
            if (key_name in files) {
                continue;
            }
            btn = (PinnedIconButton) app.get_button();
            /* We have a removal. */
            if (app.get_window_num() == 0) {
                // removing button from a closed application
                kill_button(btn);
            } else {
                // application is opened. We need to create an IconButton for it
                // in the non-pinned portion of the tray
                IconButton b2 = new IconButton(settings, icon_size, this.helper, panel_size, this, this);
                var button_wrap = new ButtonWrapper(b2);
                // replace the application's pinned button by a non-pinned version
                replace_application_button(app, b2);

                // remove the old, pinned, button
                kill_button(btn);
                // add the new non-pinned button
                widget.pack_start(button_wrap, false, false, 0);
                button_wrap.set_reveal_child(true);
            }
            removals += key_name;
        }

        foreach (string rkey in removals)
        {
            pinned_apps.remove(rkey);
        }
    }

    protected void on_settings_change(string key)
    {
        if (key != kPinningSettingsKey) {
            return;
        }

        // get current list of pinned apps
        string[] files = settings.get_strv(kPinningSettingsKey);

        insert_new_pinned_buttons(files);
        remove_unpinned_buttons(files);

        /* Properly reorder the children */
        int j = 0;
        for (int i = 0; i < files.length; i++) {
            string lkey = files[i];
            if (!pinned_apps.contains(lkey)) {
                continue;
            }
            unowned Gtk.Widget? parent = pinned_apps[lkey].get_button().get_parent();
            pinned.reorder_child(parent, j);
            ++j;
        }
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklist));
}
