/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
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
    public int intended_size { public get ; public set ; }

    public MainPanel(int size)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.intended_size = size;
        get_style_context().add_class("arc-panel");
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = intended_size - 5;
        n = intended_size - 5;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = intended_size - 5;
        n = intended_size - 5;
    }
}

/**
 * The toplevel window for a panel
 */
public class Panel : Arc.Toplevel
{

    Gdk.Rectangle scr;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;
    Gtk.Box main_layout;

    public Settings settings { construct set ; public get; }
    private unowned Arc.PanelManager? manager;

    PopoverManager? popover_manager;
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

    /* Box for the start of the panel */
    Gtk.Box? start_box;
    /* Box for the center of the panel */
    Gtk.Box? center_box;
    /* Box for the end of the panel */
    Gtk.Box? end_box;

    /**
     * Force update the geometry
     */
    public void update_geometry(Gdk.Rectangle screen, PanelPosition position, int size = 0)
    {
        Gdk.Rectangle small = screen;
        string old_class = Arc.position_class_name(this.position);
        if (old_class != "") {
            this.get_style_context().remove_class(old_class);
        }

        if (size == 0) {
            size = intended_size;
        }

        this.settings.set_int(Arc.PANEL_KEY_SIZE, size);

        this.intended_size = size;

        this.get_style_context().add_class(Arc.position_class_name(position));

        switch (position) {
            case PanelPosition.TOP:
            case PanelPosition.BOTTOM:
                small.height = intended_size;
                break;
            default:
                small.width = intended_size;
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
        this.layout.queue_resize();
        queue_resize();
        placement();
    }

    public override void reset_shadow()
    {
        this.shadow.required_size = this.orig_scr.width;
        this.shadow.removal = 0;
    }
        

    public Panel(Arc.PanelManager? manager, string? uuid, Settings? settings)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, window_position: Gtk.WindowPosition.NONE, settings: settings, uuid: uuid);

        intended_size = settings.get_int(Arc.PANEL_KEY_SIZE);
        this.manager = manager;
    
        scale = get_scale_factor();

        popover_manager = new PopoverManagerImpl(this);
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


        layout = new MainPanel(intended_size);
        layout.vexpand = false;
        vexpand = false;
        main_layout.pack_start(layout, false, false, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        shadow = new Arc.ShadowBlock(this.position);
        shadow.no_show_all = true;
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        main_layout.pack_start(shadow, false, false, 0);

        this.settings.bind(Arc.PANEL_KEY_SHADOW, shadow, "visible", SettingsBindFlags.GET);

        shadow_visible = this.settings.get_boolean(Arc.PANEL_KEY_SHADOW);
        this.settings.bind(Arc.PANEL_KEY_SHADOW, this, "shadow-visible", SettingsBindFlags.DEFAULT);

        this.bind_property("shadow-width", shadow, "removal");
        this.bind_property("intended-size", layout, "intended-size");

        /* Assign our applet holder boxes */
        start_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_start(start_box, true, true, 0);
        center_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.set_center_widget(center_box);
        end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.pack_end(end_box, true, true, 0);

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

    public void create_default_layout()
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
        unowned Gtk.Box? pack_target = null;

        message("adding %s: %s", info.name, info.uuid);

        /* figure out the alignment */
        switch (info.alignment) {
            case "start":
                pack_target = start_box;
                break;
            case "end":
                pack_target = end_box;
                break;
            default:
                pack_target = center_box;
                break;
        }

        this.applets.insert(info.uuid, info);
        this.set_applets();

        info.applet.update_popovers(this.popover_manager);

        /* Pack type */
        switch (info.pack_type) {
            case "start":
                pack_target.pack_start(info.applet, false, false, 0);
                break;
            default:
                pack_target.pack_end(info.applet, false, false, 0);
                break;
        }
        info.applet.valign = Gtk.Align.START;
        info.notify.connect(applet_updated);
    }

    void applet_updated(Object o, ParamSpec p)
    {
        unowned AppletInfo? info = o as AppletInfo;

        if (p.name == "alignment") {
            /* Handle being reparented. */
            unowned Gtk.Box? new_parent = null;
            switch (info.alignment) {
                case "start":
                    new_parent = this.start_box;
                    break;
                case "end":
                    new_parent = this.end_box;
                    break;
                default:
                    new_parent = this.center_box;
                    break;
            }
            /* Don't needlessly reparent */
            if (new_parent == info.applet.get_parent()) {
                return;
            }
            int position = (int) new_parent.get_children().length() - 1;
            if (position < 0) {
                position = 0;
            }
            info.applet.reparent(new_parent);
            /* Reset to "start" pack - might change in future */
            info.pack_type = "start";
            /* We need to be packed after all the other widgets */
            info.position = position;
            return;
        } else if (p.name == "pack-type") {
            /* Swap the pack type */
            Gtk.PackType t;

            switch (info.pack_type) {
                case "start":
                    t = Gtk.PackType.START;
                    break;
                default:
                    t = Gtk.PackType.END;
                    break;
            }
            info.applet.get_parent().child_set(info.applet, "pack-type", t);
            return;
        } /* TODO: Implement position knowledge */
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
        Arc.set_struts(this, position, (intended_size - 5)*this.scale);
        switch (position) {
            case Arc.PanelPosition.TOP:
                if (main_layout.valign != Gtk.Align.START) {
                    main_layout.valign = Gtk.Align.START;
                }
                set_gravity(Gdk.Gravity.NORTH_WEST);
                move(orig_scr.x, orig_scr.y);
                main_layout.child_set(shadow, "position", 1);
                break;
            default:
                if (main_layout.valign != Gtk.Align.END) {
                    main_layout.valign = Gtk.Align.END;
                }
                set_gravity(Gdk.Gravity.SOUTH_WEST);
                move(orig_scr.x, orig_scr.y+(orig_scr.height-intended_size));
                main_layout.child_set(shadow, "position", 0);
                break;
        }
    }
}

} // End namespace

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */
