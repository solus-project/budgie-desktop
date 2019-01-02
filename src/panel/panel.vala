/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2019 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

using LibUUID;

namespace Budgie
{

/**
 * The main panel area - i.e. the bit that's rendered
 */
public class MainPanel : Gtk.Box
{
 
    public MainPanel()
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        get_style_context().add_class("budgie-panel");
        get_style_context().add_class(Gtk.STYLE_CLASS_BACKGROUND);
    }

    public void set_transparent(bool transparent) {
        if (transparent) {
            get_style_context().add_class("transparent");
        } else {
            get_style_context().remove_class("transparent");
        }
    }

    public void set_dock_mode(bool dock_mode) {
        if (dock_mode) {
            get_style_context().add_class("dock-mode");
        } else {
            get_style_context().add_class("dock-mode");
        }
    }
}

/**
 * This is used to track panel animations, i.e. within the toplevel
 * itself to provide dock like behavior
 */
public enum PanelAnimation {

    NONE = 0,
    SHOW,
    HIDE
}

/**
 * The toplevel window for a panel
 */
public class Panel : Budgie.Toplevel
{
    Gtk.Box layout;
    Gtk.Box main_layout;
    Gdk.Rectangle orig_scr;

    public Settings settings { construct set ; public get; }
    private unowned Budgie.PanelManager? manager;

    PopoverManager? popover_manager;

    Budgie.ShadowBlock shadow;

    HashTable<string,HashTable<string,string>> pending = null;
    HashTable<string,HashTable<string,string>> creating = null;
    HashTable<string,Budgie.AppletInfo?> applets = null;

    HashTable<string,Budgie.AppletInfo?> initial_config = null;

    List<string?> expected_uuids;

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

    int[] icon_sizes = {
        16, 24, 32, 48, 96, 128, 256
    };

    int current_icon_size;
    int current_small_icon_size;

    /* Track initial load */
    private bool is_fully_loaded = false;
    private bool need_migratory = false;

    public signal void panel_loaded();

    /* Animation tracking */
    private double render_scale = 0.0;
    private PanelAnimation animation = PanelAnimation.SHOW;
    private bool allow_animation = false;
    private bool screen_occluded = false;

    public double nscale {
        public set {
            render_scale = value;
            queue_draw();
        }
        public get {
            return render_scale;
        }
        //default = 0.0;
    }

    public bool activate_action(int remote_action)
    {
        unowned string? uuid = null;
        unowned Budgie.AppletInfo? info = null;

        Budgie.PanelAction action = (Budgie.PanelAction)remote_action;

        var iter = HashTableIter<string?,Budgie.AppletInfo?>(applets);
        while (iter.next(out uuid, out info)) {
            if ((info.applet.supported_actions & action) != 0) {
                this.present();

                Idle.add(()=> {
                    info.applet.invoke_action(action);
                    return false;
                });
                return true;
            }
        }
        return false;
    }

    /**
     * Force update the geometry
     */
    public void update_geometry(Gdk.Rectangle screen, PanelPosition position, int size = 0)
    {
        this.orig_scr = screen;
        string old_class = Budgie.position_class_name(this.position);

        if (old_class != "") {
            this.get_style_context().remove_class(old_class);
        }

        if (size == 0) {
            size = intended_size;
        }

        this.settings.set_int(Budgie.PANEL_KEY_SIZE, size);
        this.intended_size = size;
        this.get_style_context().add_class(Budgie.position_class_name(position));

        // Check if the position has been altered and notify our applets
        if (position != this.position) {
            this.position = position;
            this.settings.set_enum(Budgie.PANEL_KEY_POSITION, position);
            this.update_positions();
        }

        this.shadow.position = position;
        this.layout.queue_resize();
        queue_resize();
        queue_draw();
        placement();
        update_sizes();
    }

    public void update_transparency(PanelTransparency transparency)
    {
        this.transparency = transparency;

        switch (transparency) {
            case PanelTransparency.ALWAYS:
                set_transparent(true);
                break;
            case PanelTransparency.DYNAMIC:
                manager.check_windows();
                break;
            default:
                set_transparent(false);
                break;
        }

        this.settings.set_enum(Budgie.PANEL_KEY_TRANSPARENCY, transparency);
    }

    public void set_transparent(bool transparent) {
        (layout as MainPanel).set_transparent(transparent);
        this.update_dock_behavior();
    }

    /**
     * Specific for docks, regardless of transparency, and determines
     * how our "screen blocked by thingy" policy works.
     */
    public void set_occluded(bool occluded) {
        this.screen_occluded = occluded;
        if (this.autohide == AutohidePolicy.NONE) {
            return;
        }
        this.update_dock_behavior();
    }

    public override GLib.List<AppletInfo?> get_applets()
    {
        GLib.List<Budgie.AppletInfo?> ret = new GLib.List<Budgie.AppletInfo?>();
        unowned string? key = null;
        unowned Budgie.AppletInfo? appl_info = null;

        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);
        while (iter.next(out key, out appl_info)) {
            ret.append(appl_info);
        }
        return ret;
    }

    /**
     * Loop the applets, performing a reparent or reposition
     */
    private void initial_applet_placement(bool repar = false, bool repos = false)
    {
        if (!repar && !repos) {
            return;
        }
        unowned string? uuid = null;
        unowned Budgie.AppletInfo? info = null;

        var iter = HashTableIter<string?,Budgie.AppletInfo?>(applets);

        while (iter.next(out uuid, out info)) {
            if (repar) {
                applet_reparent(info);
            }
            if (repos) {
                applet_reposition(info);
            }
        }
    }

    /* Handle being "fully" loaded */
    private void on_fully_loaded()
    {
        if (applets.size() < 1) {
            if (!initial_anim) {
                Idle.add(initial_animation);
            }
            return;
        }

        /* All applets loaded and positioned, now re-sort them */
        initial_applet_placement(true, false);
        initial_applet_placement(false, true);

        /* Let everyone else know we're in business */
        applets_changed();
        if (!initial_anim) {
            Idle.add(initial_animation);
        }
        lock (need_migratory) {
            if (!need_migratory) {
                return;
            }
        }
        /* In half a second, add_migratory so the user sees them added */
        Timeout.add(500, add_migratory);
    }

    public Panel(Budgie.PanelManager? manager, string? uuid, Settings? settings)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK, window_position: Gtk.WindowPosition.NONE, settings: settings, uuid: uuid);

        initial_config = new HashTable<string,Budgie.AppletInfo>(str_hash, str_equal);

        intended_size = settings.get_int(Budgie.PANEL_KEY_SIZE);
        this.manager = manager;

        skip_taskbar_hint = true;
        skip_pager_hint = true;
        set_decorated(false);

        scale = get_scale_factor();
        nscale = 1.0;

        // Respond to a scale factor change
        notify["scale-factor"].connect(()=> {
            this.scale = get_scale_factor();
            this.placement();
        });
        // Handle intelligent dock behavior
        notify["intersected"].connect(()=> {
            if (this.autohide != AutohidePolicy.NONE) {
                this.update_dock_behavior();
            }
        });

        popover_manager = new PopoverManager();
        pending = new HashTable<string,HashTable<string,string>>(str_hash, str_equal);
        creating = new HashTable<string,HashTable<string,string>>(str_hash, str_equal);
        applets = new HashTable<string,Budgie.AppletInfo?>(str_hash, str_equal);
        expected_uuids = new List<string?>();
        panel_loaded.connect(on_fully_loaded);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;
        get_style_context().add_class("budgie-container");

        main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);

        layout = new MainPanel();
        layout.valign = Gtk.Align.FILL;
        layout.halign = Gtk.Align.FILL;

        main_layout.pack_start(layout, true, true, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        shadow = new Budgie.ShadowBlock(this.position);
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.FILL;
        shadow.show_all();
        main_layout.pack_start(shadow, false, false, 0);

        this.settings.bind(Budgie.PANEL_KEY_SHADOW, shadow, "active", SettingsBindFlags.GET);
        this.settings.bind(Budgie.PANEL_KEY_DOCK_MODE, this, "dock-mode", SettingsBindFlags.DEFAULT);

        this.notify["dock-mode"].connect(this.update_dock_mode);

        shadow_visible = this.settings.get_boolean(Budgie.PANEL_KEY_SHADOW);
        this.settings.bind(Budgie.PANEL_KEY_SHADOW, this, "shadow-visible", SettingsBindFlags.DEFAULT);

        /* Assign our applet holder boxes */
        start_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        start_box.halign = Gtk.Align.START;
        layout.pack_start(start_box, false, false, 0);
        center_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        layout.set_center_widget(center_box);
        end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
        layout.pack_end(end_box, false, false, 0);
        end_box.halign = Gtk.Align.END;

        this.theme_regions = this.settings.get_boolean(Budgie.PANEL_KEY_REGIONS);
        this.notify["theme-regions"].connect(update_theme_regions);
        this.settings.bind(Budgie.PANEL_KEY_REGIONS, this, "theme-regions", SettingsBindFlags.DEFAULT);
        this.update_theme_regions();

        this.size_allocate.connect_after(this.do_size_allocate);
        this.enter_notify_event.connect(on_enter_notify);
        this.leave_notify_event.connect(on_leave_notify);

        get_child().show_all();

        this.manager.extension_loaded.connect_after(this.on_extension_loaded);

        /* bit of a no-op. */
        update_sizes();
        load_applets();
    }

    void do_size_allocate()
    {
        this.update_screen_edge();
    }

    void update_theme_regions()
    {
        if (this.theme_regions) {
            start_box.get_style_context().add_class("start-region");
            center_box.get_style_context().add_class("center-region");
            end_box.get_style_context().add_class("end-region");
        } else {
            start_box.get_style_context().remove_class("start-region");
            center_box.get_style_context().remove_class("center-region");
            end_box.get_style_context().remove_class("end-region");
        }
        this.queue_draw();
    }

    void update_sizes()
    {
        int size = icon_sizes[0];
        int small_size = icon_sizes[0];

        unowned string? key = null;
        unowned Budgie.AppletInfo? info = null;

        for (int i = 1; i < icon_sizes.length; i++) {
            if (icon_sizes[i] > intended_size - 5) {
                break;
            }
            size = icon_sizes[i];
            small_size = icon_sizes[i-1];
        }

        this.current_icon_size = size;
        this.current_small_icon_size = small_size;

        var iter = HashTableIter<string?,Budgie.AppletInfo?>(applets);
        while (iter.next(out key, out info)) {
            info.applet.panel_size_changed(intended_size, size, small_size);
        }
    }

    void update_positions()
    {
        unowned string? key = null;
        unowned Budgie.AppletInfo? info = null;

        var iter = HashTableIter<string?,Budgie.AppletInfo?>(applets);
        while (iter.next(out key, out info)) {
            info.applet.panel_position_changed(this.position);
        }
    }

    public void destroy_children()
    {
        unowned string key;
        unowned AppletInfo? info;

        var iter = HashTableIter<string?,AppletInfo?>(applets);
        while (iter.next(out key, out info)) {
            Settings? app_settings = info.applet.get_applet_settings(info.uuid);
            if (app_settings != null) {
                app_settings.ref();
            }

            // Stop it screaming when it dies
            ulong notify_id = info.get_data("notify_id");

            SignalHandler.disconnect(info, notify_id);
            info.applet.get_parent().remove(info.applet);

            // Clean up the settings
            this.manager.reset_dconf_path(info.settings);

            // Nuke it's own settings
            if (app_settings != null) {
                this.manager.reset_dconf_path(app_settings);
            }
        }
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
                Budgie.AppletInfo? info = this.manager.load_applet_instance(uuid, out uname);
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
                Budgie.AppletInfo? info = this.manager.create_new_applet(name, uuid);
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
        string[]? applets = settings.get_strv(Budgie.PANEL_KEY_APPLETS);
        if (applets == null || applets.length == 0) {
            this.panel_loaded();
            this.is_fully_loaded = true;
            return;
        }

        /* Two loops so we can track when we've fully loaded the panel */
        lock (expected_uuids) {
            for (int i = 0; i < applets.length; i++) {
                this.expected_uuids.append(applets[i]);
            }

            for (int i = 0; i < applets.length; i++) {
                string? name = null;
                Budgie.AppletInfo? info = this.manager.load_applet_instance(applets[i], out name);

                if (info == null) {
                    /* Faiiiil */
                    if (name == null) {
                        unowned List<string?> g = expected_uuids.find_custom(applets[i], GLib.strcmp);
                        /* TODO: No longer expecting this guy to load */
                        if (g != null) {
                            expected_uuids.remove_link(g);
                        }
                        message("Unable to load invalid applet: %s", applets[i]);
                        continue;
                    }
                    this.add_pending(applets[i], name);
                    manager.modprobe(name);
                } else {
                    /* um add this bro to the panel :o */
                    this.add_applet(info);
                }
            }
        }
    }

    /**
     * Add a new applet to the panel (Raven UI)
     *
     * Explanation: Try to find the most underpopulated region first,
     * and add the applet there. Determine a suitable position,
     * set the alignment+position, stuff an initial config in,
     * and hope for the best when we initiate add_new
     *
     * If the @target_region is set, we'll use that instead
     */
    private void add_new_applet_at(string id, Gtk.Box? target_region)
    {
        /* First, determine a panel to place this guy */
        int position = (int) applets.size() + 1;
        unowned Gtk.Box? target = null;
        string? align = null;
        AppletInfo? info = null;
        string? uuid = null;

        Gtk.Box?[] regions = {
            start_box,
            center_box,
            end_box
        };

        /* Use the requested target_region for internal migration adds */
        if (target_region != null) {
            var kids = target_region.get_children();
            position = (int) (kids.length());
            target = target_region;
        } else {
            /* No region specified, find the first available slot */
            foreach (var region in regions) {
                var kids = region.get_children();
                var len = kids.length();
                if (len < position) {
                    position = (int)len;
                    target = region;
                }
            }
        }

        if (target == start_box) {
            align = "start";
        } else if (target == center_box) {
            align = "center";
        } else {
            align = "end";
        }

        uuid = LibUUID.new(UUIDFlags.LOWER_CASE|UUIDFlags.TIME_SAFE_TYPE);
        info = new AppletInfo(null, uuid, null, null);
        info.alignment = align;

        /* Safety clamp */
        var kids = target.get_children();
        uint nkids = kids.length();
        if (position >= nkids) {
            position = (int) nkids;
        }
        if (position < 0) {
            position = 0;
        }

        info.position = position;

        initial_config.insert(uuid, info);
        add_new(id, uuid);
    }

    /**
     * Add a new applet to the panel (Raven UI)
     */
    public override void add_new_applet(string id)
    {
        add_new_applet_at(id, null);
    }

    public void create_default_layout(string name, KeyFile config)
    {
        int s_index = -1;
        int c_index = -1;
        int e_index = -1;
        int index = 0;

        try {
            if (!config.has_key(name, "Children")) {
                warning("Config for panel %s does not specify applets", name);
                return;
            }
            string[] applets = config.get_string_list(name, "Children");
            foreach (string appl in applets) {
                AppletInfo? info = null;
                string? uuid = null;
                appl = appl.strip();
                string alignment = "start"; /* center, end */

                if (!config.has_group(appl)) {
                    warning("Panel applet %s missing from config", appl);
                    continue;
                }

                if (!config.has_key(appl, "ID")) {
                    warning("Applet %s is missing ID", appl);
                    continue;
                }

                uuid = LibUUID.new(UUIDFlags.LOWER_CASE|UUIDFlags.TIME_SAFE_TYPE);

                var id = config.get_string(appl, "ID").strip();
                if (uuid == null || uuid.strip() == "") {
                    warning("Could not add new applet %s from config %s", id, name);
                    continue;
                }

                info = new AppletInfo(null, uuid, null, null);
                if (config.has_key(appl, "Alignment")) {
                    alignment = config.get_string(appl, "Alignment").strip();
                }

                switch (alignment) {
                    case "center":
                        index = ++c_index;
                        break;
                    case "end":
                        index = ++e_index;
                        break;
                    default:
                        index = ++s_index;
                        break;
                }
                info.alignment = alignment;
                info.position = index;

                initial_config.insert(uuid, info);
                add_new(id, uuid);
            }
        } catch (Error e) {
            warning("Error loading default config: %s", e.message);
        }
    }

    void set_applets()
    {
        string[]? uuids = null;
        unowned string? uuid = null;
        unowned Budgie.AppletInfo? plugin = null;

        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);
        while (iter.next(out uuid, out plugin)) {
            uuids += uuid;
        }

        settings.set_strv(Budgie.PANEL_KEY_APPLETS, uuids);
    }

    public override void remove_applet(Budgie.AppletInfo? info)
    {
        int position = info.position;
        string alignment = info.alignment;
        string uuid = info.uuid;

        ulong notify_id = info.get_data("notify_id");

        SignalHandler.disconnect(info, notify_id);
        info.applet.get_parent().remove(info.applet);

        Settings? app_settings = info.applet.get_applet_settings(uuid);
        if (app_settings != null) {
            app_settings.ref();
        }

        this.manager.reset_dconf_path(info.settings);

        /* TODO: Add refcounting and unload unused plugins. */
        applets.remove(uuid);
        applet_removed(uuid);

        if (app_settings != null) {
            this.manager.reset_dconf_path(app_settings);
        }

        set_applets();
        budge_em_left(alignment, position);
    }

    void add_applet(Budgie.AppletInfo? info)
    {
        unowned Gtk.Box? pack_target = null;
        Budgie.AppletInfo? initial_info = null;

        initial_info = initial_config.lookup(info.uuid);
        if (initial_info != null) {
            info.alignment = initial_info.alignment;
            info.position = initial_info.position;
            initial_config.remove(info.uuid);
        }

        if (!this.is_fully_loaded) {
            lock (expected_uuids) {
                unowned List<string?> exp_fin = expected_uuids.find_custom(info.uuid, GLib.strcmp);
                if (exp_fin != null) {
                    expected_uuids.remove_link(exp_fin);
                }
            }
        }

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
        info.applet.panel_size_changed(intended_size, this.current_icon_size, this.current_small_icon_size);
        info.applet.panel_position_changed(this.position);
        pack_target.pack_start(info.applet, false, false, 0);

        pack_target.child_set(info.applet, "position", info.position);
        ulong id = info.notify.connect(applet_updated);
        info.set_data("notify_id", id);
        this.applet_added(info);

        if (this.is_fully_loaded) {
            return;
        }

        lock (expected_uuids) {
            if (expected_uuids.length() == 0) {
                this.is_fully_loaded = true;
                this.panel_loaded();
            }
        }
    }

    void applet_reparent(Budgie.AppletInfo? info)
    {
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
        var current_parent = info.applet.get_parent();
        if (new_parent != current_parent) {
            current_parent.remove(info.applet);
            new_parent.add(info.applet);
            info.applet.queue_resize();
            new_parent.queue_draw();
        }
    }

    void applet_reposition(Budgie.AppletInfo? info)
    {
        info.applet.get_parent().child_set(info.applet, "position", info.position);
    }

    void applet_updated(Object o, ParamSpec p)
    {
        unowned AppletInfo? info = o as AppletInfo;

        /* Prevent a massive amount of resorting */
        if (!this.is_fully_loaded) {
            return;
        }

        if (p.name == "alignment") {
            applet_reparent(info);
        } else if (p.name == "position") {
            applet_reposition(info);
        }
        this.applets_changed();
    }

    void add_new(string plugin_name, string? initial_uuid = null)
    {
        string? uuid = null;
        unowned HashTable<string,string>? table = null;

        if (!this.manager.is_extension_valid(plugin_name)) {
            warning("Not loading invalid plugin: %s", plugin_name);
            return;
        }
        if (initial_uuid == null) {
            uuid = LibUUID.new(UUIDFlags.LOWER_CASE|UUIDFlags.TIME_SAFE_TYPE);
        } else {
            uuid = initial_uuid;
        }

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
        Budgie.AppletInfo? info = this.manager.create_new_applet(plugin_name, uuid);
        if (info == null) {
            critical("Failed to load applet when we know it exists");
            return;
        }
        this.add_applet(info);
        return;
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
        Budgie.AppletInfo? info = this.manager.load_applet_instance(uuid, out rname);
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

    public void set_autohide_policy(AutohidePolicy policy)
    {
        if (policy != this.autohide) {
            this.settings.set_enum(Budgie.PANEL_KEY_AUTOHIDE, policy);
            this.autohide = policy;
            this.apply_strut_policy();
            this.update_dock_behavior();
        }
    }

    /**
     * Update the internal representation of the panel based on whether
     * we're in dock mode or not
     */
    void update_dock_mode()
    {
        (this.layout as MainPanel).set_dock_mode(this.dock_mode);
        this.placement();
    }

    int old_width = 0;
    int old_height = 0;

    void update_screen_edge()
    {
        Gtk.Allocation alloc;
        main_layout.get_allocation(out alloc);
        int x = 0, y = 0;
        int nx = 0, ny = 0;
        int nw = 0, nh = 0;
        this.get_position(out nx, out ny);
        this.get_size(out nw, out nh);

        if (this.dock_mode) {
            switch (position) {
            case Budgie.PanelPosition.TOP:
                x = (orig_scr.x / 2) + (((orig_scr.x + orig_scr.width) / 2)  - (alloc.width / 2));
                if (x < orig_scr.x) {
                    x = orig_scr.x;
                }
                y = orig_scr.y;
                break;
            case Budgie.PanelPosition.LEFT:
                x = orig_scr.x;
                y = (orig_scr.y / 2) + (((orig_scr.y + orig_scr.height) / 2) - (alloc.height / 2));
                if (y < orig_scr.y) {
                    y = orig_scr.y;
                }
                break;
            case Budgie.PanelPosition.RIGHT:
                x = (orig_scr.x + orig_scr.width) - intended_size - 5;
                y = (orig_scr.y / 2) + (((orig_scr.y + orig_scr.height) / 2) - (alloc.height / 2));
                if (y < orig_scr.y) {
                    y = orig_scr.y;
                }
                break;
            case Budgie.PanelPosition.BOTTOM:
            default:
                x = (orig_scr.x / 2) + (((orig_scr.x + orig_scr.width) / 2)  - (alloc.width / 2));
                y = orig_scr.y + (orig_scr.height - intended_size);
                if (x < orig_scr.x) {
                    x = orig_scr.x;
                }
                break;
            }
        } else {
            switch (position) {
            case Budgie.PanelPosition.TOP:
                x = orig_scr.x;
                y = orig_scr.y;
                break;
            case Budgie.PanelPosition.LEFT:
                x = orig_scr.x;
                y = orig_scr.y;
                break;
            case Budgie.PanelPosition.RIGHT:
                x = (orig_scr.x + orig_scr.width) - intended_size - 5;
                y = orig_scr.y;
                break;
            case Budgie.PanelPosition.BOTTOM:
            default:
                x = orig_scr.x;
                y = orig_scr.y + (orig_scr.height - intended_size);
                break;
            }
        }

        // Don't update input regions unless needed
        if (old_width != nw || old_height != nh) {
            if (get_visible()) {
                this.set_input_region();
            }
            old_width = nw;
            old_height = nh;
        }

        // Don't move if we don't need to.
        if (nx == x && ny == y) {
            return;
        }

        move(x, y);
        this.queue_draw();
    }

    void apply_strut_policy()
    {
        if (this.autohide != AutohidePolicy.NONE) {
            Budgie.unset_struts(this);
        } else {
            Budgie.set_struts(this, position, (intended_size - 5) * this.scale);
        }
    }

    void placement()
    {
        this.apply_strut_policy();
        bool horizontal = false;
        Gtk.Allocation alloc;
        main_layout.get_allocation(out alloc);

        int width = 0, height = 0;
        int x = 0, y = 0;
        int shadow_position = 0;

        switch (position) {
            case Budgie.PanelPosition.TOP:
                x = orig_scr.x;
                y = orig_scr.y;
                width = orig_scr.width;
                height = intended_size - 5;
                shadow_position = 1;
                horizontal = true;
                break;
            case Budgie.PanelPosition.LEFT:
                x = orig_scr.x;
                y = orig_scr.y;
                width = intended_size;
                height = orig_scr.height;
                shadow_position = 1;
                break;
            case Budgie.PanelPosition.RIGHT:
                x = (orig_scr.x + orig_scr.width) - intended_size - 5;
                y = orig_scr.y;
                width = intended_size;
                height = orig_scr.height;
                shadow_position = 0;
                break;
            case Budgie.PanelPosition.BOTTOM:
            default:
                x = orig_scr.x;
                y = orig_scr.y + (orig_scr.height - intended_size - 5);
                width = orig_scr.width;
                height = intended_size - 5;
                shadow_position = 0;
                horizontal = true;
                break;
        }

        // Special considerations for dock mode
        if (this.dock_mode) {
            if (horizontal) {
                if (alloc.width > orig_scr.width) {
                    width = orig_scr.width;
                } else {
                    width = 100;
                }
            } else {
                if (alloc.height > orig_scr.height) {
                    height = orig_scr.height;
                } else {
                    height = 100;
                }
            }
        }

        main_layout.child_set(shadow, "position", shadow_position);

        if (horizontal) {
            start_box.halign = Gtk.Align.START;
            center_box.halign = Gtk.Align.CENTER;
            end_box.halign = Gtk.Align.END;

            start_box.valign = Gtk.Align.FILL;
            center_box.valign = Gtk.Align.FILL;
            end_box.valign = Gtk.Align.FILL;

            start_box.set_orientation(Gtk.Orientation.HORIZONTAL);
            center_box.set_orientation(Gtk.Orientation.HORIZONTAL);
            end_box.set_orientation(Gtk.Orientation.HORIZONTAL);
            layout.set_orientation(Gtk.Orientation.HORIZONTAL);

            main_layout.set_orientation(Gtk.Orientation.VERTICAL);
            main_layout.valign = Gtk.Align.FILL;
            if (this.dock_mode) {
                main_layout.halign = Gtk.Align.START;
            } else {
                main_layout.halign = Gtk.Align.FILL;
            }
            main_layout.hexpand = false;
            layout.valign = Gtk.Align.FILL;
        } else {
            start_box.halign = Gtk.Align.FILL;
            center_box.halign = Gtk.Align.FILL;
            end_box.halign = Gtk.Align.FILL;

            start_box.valign = Gtk.Align.START;
            center_box.valign = Gtk.Align.CENTER;
            end_box.valign = Gtk.Align.END;

            start_box.set_orientation(Gtk.Orientation.VERTICAL);
            center_box.set_orientation(Gtk.Orientation.VERTICAL);
            end_box.set_orientation(Gtk.Orientation.VERTICAL);
            layout.set_orientation(Gtk.Orientation.VERTICAL);

            main_layout.set_orientation(Gtk.Orientation.HORIZONTAL);
            if (this.dock_mode) {
                main_layout.valign = Gtk.Align.START;
            } else {
                main_layout.valign = Gtk.Align.FILL;
            }
            main_layout.halign = Gtk.Align.FILL;
            main_layout.hexpand = true;
        }

        layout.set_size_request(width, height);
        set_size_request(width, height);
        this.update_screen_edge();
    }

    private bool applet_at_start_of_region(Budgie.AppletInfo? info)
    {
        return (info.position == 0);
    }

    private bool applet_at_end_of_region(Budgie.AppletInfo? info)
    {
        return (info.position >= info.applet.get_parent().get_children().length() - 1);
    }

    private string? get_box_left(Budgie.AppletInfo? info)
    {
        unowned Gtk.Widget? parent = null;

        if ((parent = info.applet.get_parent()) == end_box) {
            return "center";
        } else if (parent == center_box) {
            return "start";
        } else {
            return null;
        }
    }

    private string? get_box_right(Budgie.AppletInfo? info)
    {
        unowned Gtk.Widget? parent = null;

        if ((parent = info.applet.get_parent()) == start_box) {
            return "center";
        } else if (parent == center_box) {
            return "end";
        } else {
            return null;
        }
    }

    public override bool can_move_applet_left(Budgie.AppletInfo? info)
    {
        if (!applet_at_start_of_region(info)) {
            return true;
        }
        if (get_box_left(info) != null) {
            return true;
        }
        return false;
    }

    public override bool can_move_applet_right(Budgie.AppletInfo? info)
    {
        if (!applet_at_end_of_region(info)) {
            return true;
        }
        if (get_box_right(info) != null) {
            return true;
        }
        return false;
    }

    void conflict_swap(Budgie.AppletInfo? info, int old_position)
    {
        unowned string key;
        unowned Budgie.AppletInfo? val;
        unowned Budgie.AppletInfo? conflict = null;
        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);

        while (iter.next(out key, out val)) {
            if (val.alignment == info.alignment && val.position == info.position && info != val) {
                conflict = val;
                break;
            }
        }

        if (conflict == null) {
            return;
        }

        conflict.position = old_position;
    }

    void budge_em_right(string alignment, int after = -1)
    {
        unowned string key;
        unowned Budgie.AppletInfo? val;
        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);

        while (iter.next(out key, out val)) {
            if (val.alignment == alignment) {
                if (val.position > after) {
                    val.position++;
                }
            }
        }
        this.reinforce_positions();
    }

    void budge_em_left(string alignment, int after)
    {
        unowned string key;
        unowned Budgie.AppletInfo? val;
        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);

        while (iter.next(out key, out val)) {
            if (val.alignment == alignment) {
                if (val.position > after) {
                    val.position--;
                }
            }
        }
        this.reinforce_positions();
    }

    private void reinforce_positions()
    {
        unowned string key;
        unowned Budgie.AppletInfo? val;
        var iter = HashTableIter<string,Budgie.AppletInfo?>(applets);

        while (iter.next(out key, out val)) {
            applet_reposition(val);
        }

        /* We may have ugly artifacts now */
        this.queue_draw();
    }

    public override void move_applet_left(Budgie.AppletInfo? info)
    {
        string? new_home = null;
        int new_position = info.position;
        int old_position = info.position;

        if (!applet_at_start_of_region(info)) {
            new_position--;
            if (new_position < 0) {
                new_position = 0;
            }
            info.position = new_position;
            conflict_swap(info, old_position);
            applets_changed();
            return;
        }
        if ((new_home = get_box_left(info)) != null) {
            unowned Gtk.Box? new_parent = null;
            switch (info.alignment) {
                case "end":
                    new_parent = center_box;
                    break;
                case "center":
                    new_parent = start_box;
                    break;
                default:
                    new_parent = end_box;
                    break;
            }

            string old_home = info.alignment;
            uint len = new_parent.get_children().length();
            info.alignment = new_home;
            info.position = (int)len;
            budge_em_left(old_home, 0);
            applets_changed();
        }
    }

    public override void move_applet_right(Budgie.AppletInfo? info)
    {
        string? new_home = null;
        int new_position = info.position;
        int old_position = info.position;
        uint len;

        if (!applet_at_end_of_region(info)) {
            new_position++;
            len = info.applet.get_parent().get_children().length() - 1;
            if (new_position > len) {
                new_position = (int) len;
            }
            info.position = new_position;
            conflict_swap(info, old_position);
            applets_changed();
            return;
        }
        if ((new_home = get_box_right(info)) != null) {
            info.alignment = new_home;
            budge_em_right(new_home);
            info.position = 0;
            this.reinforce_positions();
            applets_changed();
        }
    }

    private bool initial_anim = false;
    private Budgie.Animation? dock_animation = null;

    private bool initial_animation()
    {
        this.allow_animation = true;
        this.initial_anim = true;

        this.show_panel();
        return false;
    }

    /**
     * Remove existing animations
     */
    private void remove_panel_animations()
    {
        if (dock_animation == null) {
            return;
        }
        dock_animation.stop();
        dock_animation = null;
        animation = PanelAnimation.NONE;
    }

    private bool render_panel = true;

    /* Track update dock requests */
    private uint update_dock_id = 0;

    private bool cursor_within_bounds()
    {
        int cx = 0, cy = 0;
        int x = 0, y = 0;
        int w = 0, h = 0;
        var display = this.get_display();
        unowned Gdk.Device? pointer = null;

        var seat = display.get_default_seat();
        pointer = seat.get_pointer();
        this.get_position(out x, out y);
        this.get_size(out w, out h);
        pointer.get_position(null, out cx, out cy);

        if ((cx >= x && cx <= x + w) && (cy >= y && cy <= y + h)) {
            return true;
        }

        return false;
    }

    /**
     * Handle dock like functionality
     */
    bool update_dock_behavior()
    {
        update_dock_id = 0;

        PanelAnimation target_state = PanelAnimation.NONE;

        if (this.autohide == AutohidePolicy.NONE) {
            this.remove_panel_animations();
            this.animation = PanelAnimation.NONE;
            this.placement();
            this.show_panel();
            return false;
        }

        /* Intellihide is basically: Are we intersected */
        if (this.autohide == AutohidePolicy.INTELLIGENT) {
            if (this.intersected) {
                target_state = PanelAnimation.HIDE;
            } else {
                target_state = PanelAnimation.SHOW;
            }
        } else {
            if (this.screen_occluded) {
                target_state = PanelAnimation.HIDE;
            } else {
                target_state = PanelAnimation.SHOW;
            }
        }

        if (target_state == PanelAnimation.SHOW && nscale == 1.0) {
            return false;
        }

        if (target_state == PanelAnimation.HIDE && nscale == 0.0) {
            return false;
        }

        this.remove_panel_animations();

        if (target_state == PanelAnimation.SHOW) {
            this.show_panel();
        } else {
            this.hide_panel();
        }
        return false;
    }

    /**
     * Unset the input region to allow peek events
     */
    private void unset_input_region()
    {
        // Set 1px input region to receive enter-notify
        render_panel = false;
        Cairo.Region? region = null;

        switch (position) {
            case PanelPosition.TOP:
                region = new Cairo.Region.rectangle(Cairo.RectangleInt() {
                    x = 0, y = 0,
                    width = get_allocated_width() * this.scale_factor,
                    height = 1 * this.scale_factor
                });
                break;
            case PanelPosition.LEFT:
                region = new Cairo.Region.rectangle(Cairo.RectangleInt() {
                    x = 0, y = 0,
                    width = 1 * this.scale_factor,
                    height = get_allocated_height() * this.scale_factor
                });
                break;
            case PanelPosition.RIGHT:
                region = new Cairo.Region.rectangle(Cairo.RectangleInt() {
                    x = (get_allocated_width() * this.scale_factor) - (1 * this.scale_factor),
                    y = 0,
                    width = 1 * this.scale_factor,
                    height = get_allocated_height() * this.scale_factor
                });
                break;
            case PanelPosition.BOTTOM:
            default:
                region = new Cairo.Region.rectangle(Cairo.RectangleInt() {
                    x = 0,
                    y = (get_allocated_height() * this.scale_factor) - (1 * this.scale_factor),
                    width = get_allocated_width() * this.scale_factor,
                    height = 1 * this.scale_factor
                });
                break;
        }

        get_window().input_shape_combine_region(region, 0, 0);
    }

    /**
     * Restore the full input region for "normal" usage
     */
    private void set_input_region()
    {
        var region = new Cairo.Region.rectangle(Cairo.RectangleInt() {
            x = 0, y = 0,
            width = get_allocated_width(),
            height = get_allocated_height()
        });
        get_window().input_shape_combine_region(region, 0, 0);
    }

    /**
     * In an autohidden mode, if we're not visible, and get peeked, say
     * hello
     */
    private bool on_enter_notify(Gdk.EventCrossing cr)
    {
        if (this.render_panel) {
            return Gdk.EVENT_PROPAGATE;
        }
        if (this.autohide == AutohidePolicy.NONE) {
            return Gdk.EVENT_PROPAGATE;
        }
        if (cr.detail == Gdk.NotifyType.INFERIOR) {
            return Gdk.EVENT_PROPAGATE;
        }

        if (update_dock_id > 0) {
            Source.remove(update_dock_id);
            update_dock_id = 0;
        }

        if (show_panel_id > 0) {
            Source.remove(show_panel_id);
        }
        show_panel_id = Timeout.add(150, this.show_panel);
        return Gdk.EVENT_STOP;
    }

    private bool on_leave_notify(Gdk.EventCrossing cr)
    {
        if (this.autohide == AutohidePolicy.NONE) {
            return Gdk.EVENT_PROPAGATE;
        }
        if (cr.detail == Gdk.NotifyType.INFERIOR) {
            return Gdk.EVENT_PROPAGATE;
        }

        if (show_panel_id > 0) {
            Source.remove(show_panel_id);
            show_panel_id = 0;
        }

        if (update_dock_id > 0) {
            Source.remove(update_dock_id);
        }
        update_dock_id = Timeout.add(175, this.update_dock_behavior);
        return Gdk.EVENT_STOP;
    }

    uint show_panel_id = 0;

    /**
     * Show the panel through a small animation
     */
    private bool show_panel()
    {
        show_panel_id = 0;

        if (!this.allow_animation) {
            return false;
        }
        this.animation = PanelAnimation.SHOW;
        render_panel = true;

        this.queue_draw();
        this.show();

        if (!this.get_settings().gtk_enable_animations) {
            this.nscale = 1.0;
            this.set_input_region();
            this.animation = PanelAnimation.NONE;
            this.queue_draw();
            return false;
        }

        this.set_input_region();

        dock_animation = new Budgie.Animation();
        dock_animation.widget = this;
        dock_animation.length = 360 * Budgie.MSECOND;
        dock_animation.tween = Budgie.expo_ease_out;
        dock_animation.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "nscale",
                old = this.nscale,
                @new = 1.0
            }
        };

        dock_animation.start((a)=> {
            this.set_input_region();
            this.animation = PanelAnimation.NONE;
        });
        return false;
    }

    /**
     * Hide the panel through a small animation
     */
    private void hide_panel()
    {
        if (!this.allow_animation) {
            return;
        }

        if (this.cursor_within_bounds()) {
            return;
        }

        if (!this.get_settings().gtk_enable_animations) {
            this.nscale = 0.0;
            this.unset_input_region();
            this.animation = PanelAnimation.NONE;
            this.queue_draw();
            return;
        }

        this.unset_input_region();

        render_panel = true;
        this.animation = PanelAnimation.SHOW;
        dock_animation = new Budgie.Animation();
        dock_animation.widget = this;
        dock_animation.length = 360 * Budgie.MSECOND;
        dock_animation.tween = Budgie.expo_ease_out;
        dock_animation.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "nscale",
                old = this.nscale,
                @new = 0.0
            }
        };

        dock_animation.start((a)=> {
            this.unset_input_region();
            this.animation = PanelAnimation.NONE;
        });
    }

    public override bool draw(Cairo.Context cr)
    {
        if (!render_panel) {
            /* Don't need to render */
            return Gdk.EVENT_STOP;
        }

        if (animation == PanelAnimation.NONE) {
            return base.draw(cr);
        }

        var window = this.get_window();
        if (window == null) {
            return Gdk.EVENT_STOP;
        }

        Gtk.Allocation alloc;
        get_allocation(out alloc);
        /* Create a compatible buffer for the current scaling factor */
        var buffer = window.create_similar_image_surface(Cairo.Format.ARGB32,
                                                         alloc.width * this.scale_factor,
                                                         alloc.height * this.scale_factor,
                                                         this.scale_factor);
        var cr2 = new Cairo.Context(buffer);

        propagate_draw(get_child(), cr2);
        var y = ((double)alloc.height) * render_scale;
        var x = ((double)alloc.width) * render_scale;

        switch (position) {
            case Budgie.PanelPosition.TOP:
                // Slide down into view
                cr.set_source_surface(buffer, 0, y - alloc.height);
                break;
            case Budgie.PanelPosition.LEFT:
                // Slide into view from left
                cr.set_source_surface(buffer, x - alloc.width, 0);
                break;
            case Budgie.PanelPosition.RIGHT:
                // Slide back into view from right
                cr.set_source_surface(buffer, alloc.width - x, 0);
                break;
            case Budgie.PanelPosition.BOTTOM:
            default:
                // Slide up into view
                cr.set_source_surface(buffer, 0, alloc.height - y);
                break;
        }

        cr.paint();

        return Gdk.EVENT_STOP;
    }

    /**
     * Specialist operation, perform a migration after we changed applet configurations
     * See: https://github.com/solus-project/budgie-desktop/issues/555
     */
    public void perform_migration(int current_migration_level)
    {
        if (current_migration_level != 0) {
            GLib.warning("Unknown migration level: %d", current_migration_level);
            return;
        }
        this.need_migratory = true;
        if (this.is_fully_loaded) {
            GLib.message("Performing migration to level %d", BUDGIE_MIGRATION_LEVEL);
            this.add_migratory();
        }
    }

    /**
     * Very simple right now. Just add the applets to the end of the panel
     */
    private bool add_migratory()
    {
        lock (need_migratory) {
            if (!need_migratory) {
                return false;
            }
            need_migratory = false;
            foreach (var new_applet in MIGRATION_1_APPLETS) {
                message("Adding migratory applet: %s", new_applet);
                add_new_applet_at(new_applet, end_box);
            }
        }
        return false;
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
