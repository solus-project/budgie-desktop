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

public class IconTasklistApplet : Budgie.Applet
{

    protected Gtk.Box widget;
    protected Gtk.Box main_layout;
    protected Gtk.Box pinned;

    protected Wnck.Screen screen;
    protected HashTable<Wnck.Window,IconButton> buttons;
    protected HashTable<string?,PinnedIconButton?> pin_buttons;
    protected int icon_size = 32;
    private Settings settings;

    protected Gdk.AppLaunchContext context;
    protected AppSystem? helper;

    private unowned IconButton? active_button;

    public string uuid { public set ; public get ; }

    protected void window_opened(Wnck.Window window)
    {
        // doesn't go on our list
        if (window.is_skip_tasklist()) {
            return;
        }
        string? launch_id = null;
        IconButton? button = null;
        if (window.get_application() != null) {
            launch_id = window.get_application().get_startup_id();
        }
        var pinfo = helper.query_window(window);

        // Check whether its launched with startup notification, if so
        // attempt to use a pin button where appropriate.
        if (launch_id != null) {
            PinnedIconButton? btn = null;
            PinnedIconButton? pbtn = null;
            var iter = HashTableIter<string?,PinnedIconButton?>(pin_buttons);
            while (iter.next(null, out pbtn)) {
                if (pbtn.id != null && startupid_match(pbtn.id, launch_id)) {
                    btn = pbtn;
                    break;
                }
            }
            if (btn != null) {
                btn.window = window;
                btn.update_from_window();
                btn.id = null;
                button = btn;
            }
        }
        // Alternatively.. find a "free slot"
        if (pinfo != null) {
            var pinfo2 = pin_buttons[pinfo.get_id()];
            if (pinfo2 != null && pinfo2.window == null) {
                pinfo2.window = window;
                pinfo2.update_from_window();
                button = pinfo2;
            }
        }

        // Fallback to new button.
        if (button == null) {
            var btn = new IconButton(settings, window, icon_size, pinfo, this.helper, panel_size);
            var button_wrap = new ButtonWrapper(btn);

            button = btn;
            widget.pack_start(button_wrap, false, false, 0);
        }
        buttons[window] = button;
        (button.get_parent() as Gtk.Revealer).set_reveal_child(true);
        Idle.add(()=> {
            button.icon_mapped();
            return false;
        });
    }

    protected void window_closed(Wnck.Window window)
    {
        IconButton? btn = null;
        if (!buttons.contains(window)) {
            return;
        }
        btn = buttons[window];
        // We'll destroy a PinnedIconButton if it got unpinned
        if (btn is PinnedIconButton && btn.get_parent() != widget) {
            var pbtn = btn as PinnedIconButton;
            pbtn.reset();
        } else {
            (btn.get_parent() as ButtonWrapper).gracefully_die();
        }
        buttons.remove(window);
    }

    /**
     * Just update the active state on the buttons
     */
    protected void active_window_changed(Wnck.Window? previous_window)
    {
        IconButton? btn;
        Wnck.Window? new_active;
        if (previous_window != null)
        {
            // Update old active button
            if (buttons.contains(previous_window)) {
                btn = buttons[previous_window];
                btn.set_active(false);
            } 
        }
        new_active = screen.get_active_window();
        if (new_active == null || !buttons.contains(new_active)) {
            active_button = null;
            queue_draw();
            return;
        }
        btn = buttons[new_active];
        btn.set_active(true);
        if (!btn.get_realized()) {
            btn.realize();
            btn.queue_resize();
        }

        active_button = btn;
        queue_draw();
    }

    public IconTasklistApplet(string uuid)
    {
        Object(uuid: uuid);

        this.context = Gdk.Screen.get_default().get_display().get_app_launch_context();

        settings_schema = "com.solus-project.icon-tasklist";
        settings_prefix = "/com/solus-project/budgie-panel/instance/icon-tasklist";

        helper = new AppSystem();

        // Easy mapping :)
        buttons = new HashTable<Wnck.Window,IconButton>(direct_hash, direct_equal);
        pin_buttons = new HashTable<string?,PinnedIconButton?>(str_hash, str_equal);

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
        unowned IconButton? val = null;
        unowned PinnedIconButton? pin_val = null;

        icon_size = small_icons;    
        Wnck.set_default_icon_size(icon_size);

        Idle.add(()=> {
            var iter = HashTableIter<Wnck.Window?,IconButton?>(buttons);
            while (iter.next(out btn_key, out val)) {
                val.icon_size = icon_size;
                val.panel_size = panel_size;
                val.update_icon();
            }

            var iter2 = HashTableIter<string?,PinnedIconButton?>(pin_buttons);
            while (iter2.next(out str_key, out pin_val)) {
                pin_val.icon_size = icon_size;
                pin_val.panel_size = panel_size;
                pin_val.update_icon();
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

            (pin_buttons[launchers[i]].get_parent() as ButtonWrapper).get_allocation(out alloc);

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

    protected void on_settings_change(string key)
    {
        if (key != "pinned-launchers") {
            return;
        }

        string[] files = settings.get_strv(key);
        /* We don't actually remove anything >_> */
        foreach (string desktopfile in settings.get_strv(key)) {
            /* Ensure we don't have this fella already. */
            if (pin_buttons.contains(desktopfile)) {
                continue;
            }
            var info = new DesktopAppInfo(desktopfile);
            if (info == null) {
                message("Invalid application! %s", desktopfile);
                continue;
            }
            var button = new PinnedIconButton(settings, info, icon_size, ref this.context, this.helper, panel_size);
            var button_wrap = new ButtonWrapper(button);
            pin_buttons[desktopfile] = button;
            pinned.pack_start(button_wrap, false, false, 0);

            // Do we already have an icon button for this?
            var iter = HashTableIter<Wnck.Window,IconButton>(buttons);
            Wnck.Window? keyn;
            IconButton? btn;
            while (iter.next(out keyn, out btn)) {
                if (btn.ainfo == null) {
                    continue;
                }
                if (btn.ainfo.get_id() == info.get_id() && btn.requested_pin) {
                    // Pinning an already active button.
                    button.window = btn.window;
                    // destroy old one
                    (btn.get_parent() as ButtonWrapper).gracefully_die();
                    buttons.remove(keyn);
                    buttons[keyn] = button;
                    button.update_from_window();
                    break;
                }
            }

            (button.get_parent() as Gtk.Revealer).set_reveal_child(true);
            Idle.add(()=> {
                button.icon_mapped();
                return false;
            });
        }
        string[] removals = {};
        /* Conversely, remove ones which have been unset. */
        var iter = HashTableIter<string?,PinnedIconButton?>(pin_buttons);
        string? key_name;
        PinnedIconButton? btn;
        while (iter.next(out key_name, out btn)) {
            if (key_name in files) {
                continue;
            }
            /* We have a removal. */
            if (btn.window == null) {
                (btn.get_parent() as ButtonWrapper).gracefully_die();
            } else {
                /* We need to move this fella.. */
                IconButton b2 = new IconButton(settings, btn.window, icon_size, (owned)btn.app_info, this.helper, panel_size);
                var button_wrap = new ButtonWrapper(b2);

                (btn.get_parent() as ButtonWrapper).gracefully_die();
                widget.pack_start(button_wrap, false, false, 0);
                buttons[b2.window]  = b2;
                button_wrap.set_reveal_child(true);
            }
            removals += key_name;
        }

        foreach (string rkey in removals) {
            pin_buttons.remove(rkey);
        }

        /* Properly reorder the children */
        int j = 0;
        for (int i = 0; i < files.length; i++) {
            string lkey = files[i];
            if (!pin_buttons.contains(lkey)) {
                continue;
            }
            unowned Gtk.Widget? parent = pin_buttons[lkey].get_parent();
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
