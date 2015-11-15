/*
 * This file is part of arc-desktop
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

using LibUUID;

namespace Arc
{

/**
 * The main panel area - i.e. the bit that's rendered
 */
public class MainPanel : Gtk.Box
{
    public int intended_size;

    public MainPanel(int size)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.intended_size = size;
        get_style_context().add_class("arc-panel");
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
}

/**
 * The toplevel window for a panel
 */
public class Panel : Gtk.Window
{

    Gdk.Rectangle scr;
    int intended_height = 42 + 5;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;
    Gtk.Box main_layout;

    public Arc.PanelPosition? position;

    public Settings settings { construct set ; public get; }
    private unowned Arc.PanelManager? manager;

    public string uuid { construct set ; public get; }

    PopoverManager popover_manager;
    bool expanded = true;

    Arc.ShadowBlock shadow;

    HashTable<string,HashTable<string,string>> pending = null;
    HashTable<string,HashTable<string,string>> creating = null;
    HashTable<string,Arc.AppletInfo?> applets = null;

    construct {
        position = PanelPosition.NONE;
    }

    /* Multiplier for strut operations on hi-dpi */
    int scale = 1;

    /**
     * Force update the geometry
     */
    public void update_geometry(Gdk.Rectangle screen, PanelPosition position)
    {
        Gdk.Rectangle small = screen;

        switch (position) {
            case PanelPosition.TOP:
            case PanelPosition.BOTTOM:
                small.height = intended_height;
                break;
            default:
                small.width = intended_height;
                break;
        }
        if (position != this.position) {
            this.settings.set_enum(Arc.PANEL_KEY_POSITION, position);
        }
        this.position = position;
        this.small_scr = small;
        this.orig_scr = screen;

        if (this.expanded) {
            this.scr = this.orig_scr;
        } else {
            this.scr = this.small_scr;
        }
        shadow.required_size = orig_scr.width;
        this.shadow.position = position;
        queue_resize();
        placement();
    }

    public Panel(Arc.PanelManager? manager, string? uuid, Settings? settings)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, window_position: Gtk.WindowPosition.NONE, settings: settings, uuid: uuid);

        this.manager = manager;
    
        scale = get_scale_factor();
        load_css();

        popover_manager = new PopoverManager(this);
        pending = new HashTable<string,HashTable<string,string>>(str_hash, str_equal);
        creating = new HashTable<string,HashTable<string,string>>(str_hash, str_equal);
        applets = new HashTable<string,Arc.AppletInfo?>(str_hash, str_equal);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;
        get_style_context().add_class("arc-container");

        main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);


        layout = new MainPanel(intended_height - 5);
        layout.vexpand = false;
        vexpand = false;
        main_layout.pack_start(layout, false, false, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        shadow = new Arc.ShadowBlock(this.position);
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        main_layout.pack_start(shadow, false, false, 0);

        get_child().show_all();
        set_expanded(false);

        this.manager.extension_loaded.connect_after(this.on_extension_loaded);
        load_applets();
    }

    void on_extension_loaded(string name)
    {
        unowned HashTable<string,string>? todo = null;
        todo = pending.lookup(name);
        if (todo != null) {
            var iter = HashTableIter<string,string>(todo);
            string? uuid = null;

            while (iter.next(out uuid, null)) {
                string? uname = null;
                Arc.AppletInfo? info = this.manager.load_applet_instance(uuid, out uname);
                if (info == null) {
                    critical("Failed to load applet when we know it exists: %s", uname);
                    return;
                }
                this.add_applet(info);
            }
            pending.remove(name);
        }

        todo = null;

        todo = creating.lookup(name);
        if (todo != null) {
            var iter = HashTableIter<string,string>(todo);
            string? uuid = null;

            while (iter.next(out uuid, null)) {
                Arc.AppletInfo? info = this.manager.create_new_applet(name, uuid);
                if (info == null) {
                    critical("Failed to load applet when we know it exists");
                    return;
                }
                this.add_applet(info);
                /* this.configure_applet(info); */
            }
            creating.remove(name);
        }
    }

    /**
     * Load all pre-configured applets
     */
    void load_applets()
    {
        string[]? applets = settings.get_strv(Arc.PANEL_KEY_APPLETS);
        if (applets == null || applets.length == 0) {
            message("No applets configured for panel %s", this.uuid);
            create_default_layout();
            return;
        }

        for (int i = 0; i < applets.length; i++) {
            string? name = null;
            Arc.AppletInfo? info = this.manager.load_applet_instance(applets[i], out name);

            if (info == null) {
                /* Faiiiil */
                if (name == null) {
                    message("Unable to load invalid applet: %s", applets[i]);
                    /* TODO: Trimmage */
                    continue;
                }
                this.add_pending(applets[i], name);
                manager.modprobe(name);
                continue;
            }
            /* um add this bro to the panel :o */
            this.add_applet(info);
        }
    }

    void create_default_layout()
    {
        message("Creating default panel layout");
        add_new("Budgie Menu Applet");
    }

    void set_applets()
    {
        string[]? uuids = null;
        unowned string? uuid = null;
        unowned Arc.AppletInfo? plugin = null;

        var iter = HashTableIter<string,Arc.AppletInfo?>(applets);
        while (iter.next(out uuid, out plugin)) {
            uuids += uuid;
        }

        settings.set_strv(Arc.PANEL_KEY_APPLETS, uuids);
    }

    void add_applet(Arc.AppletInfo? info)
    {
        message("adding %s: %s", info.name, info.uuid);
        this.applets.insert(info.uuid, info);
        this.set_applets();

        layout.pack_start(info.applet, false, false, 0);

        var table = info.applet.get_popovers();
        if (table == null) {
            return;
        }
        /* Hacky popover tests */
        var iter = HashTableIter<Gtk.Widget?,Gtk.Popover?>(table);
        unowned Gtk.Widget? widg = null;
        unowned Gtk.Popover? pop = null;
        while (iter.next(out widg, out pop)) {
            this.popover_manager.register_popover(widg,pop);
        }
    }

    void add_new(string plugin_name)
    {
        string? uuid = null;
        string? rname = null;
        unowned HashTable<string,string>? table = null;

        if (!this.manager.is_extension_valid(plugin_name)) {
            warning("Not loading invalid plugin: %s", plugin_name);
            return;
        }
        uuid = LibUUID.new(UUIDFlags.LOWER_CASE|UUIDFlags.TIME_SAFE_TYPE);

        if (!this.manager.is_extension_loaded(plugin_name)) {
            /* Request a load of the new guy */
            table = creating.lookup(plugin_name);
            if (table != null) {
                if (!table.contains(uuid)) {
                    table.insert(uuid, uuid);
                }
                return;
            }
            /* Looks insane but avoids copies */
            creating.insert(plugin_name, new HashTable<string,string>(str_hash, str_equal));
            table = creating.lookup(plugin_name);
            table.insert(uuid, uuid);
            this.manager.modprobe(plugin_name);
            return;
        }
        /* Already exists */
        Arc.AppletInfo? info = this.manager.create_new_applet(plugin_name, uuid);
        if (info == null) {
            critical("Failed to load applet when we know it exists");
            return;
        }
        this.add_applet(info);
    }

    void add_pending(string uuid, string plugin_name)
    {
        string? rname = null;
        unowned HashTable<string,string>? table = null;

        if (!this.manager.is_extension_valid(plugin_name)) {
            warning("Not adding invalid plugin: %s %s", plugin_name, uuid);
            return;
        }

        if (!this.manager.is_extension_loaded(plugin_name)) {
            /* Request a load of the new guy */
            table = pending.lookup(plugin_name);
            if (table != null) {
                if (!table.contains(uuid)) {
                    table.insert(uuid, uuid);
                }
                return;
            }
            /* Looks insane but avoids copies */
            pending.insert(plugin_name, new HashTable<string,string>(str_hash, str_equal));
            table = pending.lookup(plugin_name);
            table.insert(uuid, uuid);
            this.manager.modprobe(plugin_name);
            return;
        }

        /* Already exists */
        Arc.AppletInfo? info = this.manager.load_applet_instance(uuid, out rname);
        if (info == null) {
            critical("Failed to load applet when we know it exists");
            return;
        }
        this.add_applet(info);
    }

    public override void map()
    {
        base.map();
        placement();
    }

    void load_css()
    {
        try {
            var f = File.new_for_uri("resource://com/solus-project/arc/panel/default.css");
            var css = new Gtk.CssProvider();
            css.load_from_file(f);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);

            var f2 = File.new_for_uri("resource://com/solus-project/arc/panel/style.css");
            var css2 = new Gtk.CssProvider();
            css2.load_from_file(f2);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning("CSS Missing: %s", e.message);
        }
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }
    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }

    public void set_expanded(bool expanded)
    {
        if (this.expanded == expanded) {
            return;
        }
        this.expanded = expanded;
        if (!expanded) {
            scr = small_scr;
        } else {
            scr = orig_scr;
        }
        queue_resize();

        if (expanded) {
            present();
        }
    }

    void placement()
    {
        Arc.set_struts(this, position, (intended_height - 5)*this.scale);
        switch (position) {
            case Arc.PanelPosition.TOP:
                move(orig_scr.x, orig_scr.y);
                break;
            default:
                main_layout.valign = Gtk.Align.END;
                move(orig_scr.x, orig_scr.y+(orig_scr.height-intended_height));
                main_layout.reorder_child(shadow, 0);
                shadow.get_style_context().add_class("bottom");
                set_gravity(Gdk.Gravity.SOUTH);
                break;
        }
    }
}

} // End namespace
