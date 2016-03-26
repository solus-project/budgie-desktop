/*
 * IconTasklistApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */


/**
 * Note: Please blame Joey for any insanity in this file. Launchers is
 * what he wanted. Consequently some of this seems to make sense at first
 * glance. Then you actually *look*. Honestly, just walk away now. File
 * a bug but pretend this is a git submodule we don't maintain. Cheers.
 */

const string BUDGIE_STYLE_CLASS_BUTTON = "launcher";

/**
 * Maximum number of full flash cycles for urgency before giving up. Note
 * that the background colour will remain fully opaque until the calling
 * application then resets whatever caused the urgency/attention demand
 */
const int MAX_CYCLES = 12;

/**
 * Default opacity when beginning urgency cycles in the launcher
 */
const double DEFAULT_OPACITY = 0.1;

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



[GtkTemplate (ui = "/com/solus-project/icon-tasklist/settings.ui")]
public class IconTasklistSettings : Gtk.Grid
{


    [GtkChild]
    private Gtk.Switch? switch_large_icons;

    private Settings? settings;

    public IconTasklistSettings(Settings? settings)
    {
        this.settings = settings;
        settings.bind("larger-icons", switch_large_icons, "active", SettingsBindFlags.DEFAULT);
    }

}

/**
 * Trivial helper for IconTasklist - i.e. desktop lookups
 */
public class DesktopHelper : Object
{

    HashTable<string?,string?> simpletons;
    HashTable<string?,string?> startupids;
    static string[] derpers;

    static construct {
        derpers = new string[] {
            "google-chrome",
            "hexchat"
        };
    }

    public DesktopHelper()
    {
        /* Initialize simpletons. */
        simpletons = new HashTable<string?,string?>(str_hash, str_equal);
        simpletons["google-chrome-stable"] = "google-chrome";
        /* Constency++ */
        simpletons["gnome-clocks"] = "org.gnome.clocks";
        simpletons["gnome-calendar"] = "org.gnome.Calendar";
        simpletons["gnome-screenshot"] = "org.gnome.Screenshot";
        simpletons["nautilus"] = "org.gnome.Nautilus";
        simpletons["totem"] = "org.gnome.Totem";
        simpletons["gedit"] = "org.gnome.gedit";
        simpletons["calibre-gui"] = "calibre";

        var monitor = AppInfoMonitor.get();
        monitor.changed.connect(()=> {
            startupids = null;
            reload_ids();
        });
        reload_ids();
    }

    void reload_ids()
    {
        startupids = new HashTable<string?,string?>(str_hash,str_equal);
        foreach (var appinfo in AppInfo.get_all()) {
            var dinfo = appinfo as DesktopAppInfo;
            if (dinfo.get_startup_wm_class() != null) {
                startupids[dinfo.get_startup_wm_class()] = dinfo.get_id();
            }
        }
    }

    /**
     * Obtain a DesktopAppInfo for a given window.
     * @param window X11 window to obtain DesktopAppInfo for
     *
     * @return a DesktopAppInfo if found, otherwise null.
     * 
     * @note This is immensely inefficient. We still need to cache some
     * lookups.
     */
    public DesktopAppInfo? get_app_info_for_window(Wnck.Window? window)
    {
        if (window == null) {
            return null;
        }
        if (window.get_class_group_name() == null) {
            return null;
        }
        var app_name = window.get_class_group_name();
        string? app_name_clean;
        // track suffix in case we use startup wm class to find id
        string suffix = ".desktop";

        if (window.get_class_instance_name() in startupids) {
            app_name = startupids[window.get_class_instance_name()];
            app_name_clean = app_name;
            suffix = "";
        } else {
            var c = app_name[0].tolower();
            app_name_clean = "%c%s".printf(c,app_name[1:app_name.length]);
        }

        var p1 = new DesktopAppInfo("%s%s".printf(app_name_clean, suffix));
        if (p1 == null) {
            if (app_name_clean in simpletons) {
                p1 = new DesktopAppInfo("%s%s".printf(simpletons[app_name_clean], suffix));
            }
        }
        return p1;
    }

    public static bool has_derpy_icon(Wnck.Window? window)
    {
        if (window.get_class_instance_name() in DesktopHelper.derpers) {
            return true;
        }
        return false;
    }

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

public class IconButton : Gtk.ToggleButton
{

    public new Gtk.Image image;
    public unowned Wnck.Window? window;
    protected Wnck.ActionMenu menu;
    public int icon_size;
    public GLib.DesktopAppInfo? ainfo;
    private Gtk.MenuItem pinnage;
    private Gtk.MenuItem unpinnage;
    private Gtk.SeparatorMenuItem sep_item;

    public bool requested_pin = false;

    private bool we_urgent = false;
    private double urg_opacity = DEFAULT_OPACITY;
    protected bool should_fade_in = true;
    private uint source_id;
    protected Gtk.Allocation our_alloc;

    protected int current_cycles = 0;

    unowned Settings? settings;

    public void update_from_window()
    {
        we_urgent = false;
        if (source_id > 0) {
            remove_tick_callback(source_id);
            source_id = 0;
        }

        if (window == null) {
            if (this is PinnedIconButton) {
                this.get_style_context().remove_class("running");
            }
            return;
        }

        if (this is PinnedIconButton) {
            this.get_style_context().add_class("running");
        }
        set_tooltip_text(window.get_name());

        // Things we can happily handle ourselves
        window.icon_changed.connect(update_icon);
        window.name_changed.connect(()=> {
            set_tooltip_text(window.get_name());
        });
        update_icon();
        set_active(window.is_active());
        window.state_changed.connect(on_state_changed);

        // Actions menu
        menu = new Wnck.ActionMenu(window);

        var sep = new Gtk.SeparatorMenuItem();
        menu.append(sep);
        sep_item = sep;
        pinnage = new Gtk.MenuItem.with_label("Pin to panel");
        unpinnage = new Gtk.MenuItem.with_label("Unpin from panel");
        sep.show();
        menu.append(pinnage);
        menu.append(unpinnage);

        /* Handle running instance pin/unpin */
        pinnage.activate.connect(()=> {
            requested_pin = true;
            DesktopHelper.set_pinned(settings, ainfo, true);
        });

        unpinnage.activate.connect(()=> {
            if (this is /*Sparta*/ PinnedIconButton) {
                var p = this as PinnedIconButton;
                DesktopHelper.set_pinned(settings, p.app_info, false);
            }
        });

        if (ainfo != null) {
            // Desktop app actions =)
            unowned string[] actions = ainfo.list_actions();
            if (actions.length == 0) {
                return;
            }
            sep = new Gtk.SeparatorMenuItem();
            menu.append(sep);
            sep.show_all();
            foreach (var action in actions) {
                var display_name = ainfo.get_action_name(action);
                var item = new Gtk.MenuItem.with_label(display_name);
                item.set_data("__aname", action);
                item.activate.connect(()=> {
                    string? act = item.get_data("__aname");
                    if (act == null) {
                        return;
                    }
                    // Never know.
                    if (ainfo == null) {
                        return;
                    }
                    var launch_context = Gdk.Screen.get_default().get_display().get_app_launch_context();
                    launch_context.set_screen(get_screen());
                    launch_context.set_timestamp(Gdk.CURRENT_TIME);
                    ainfo.launch_action(act, launch_context);
                });
                item.show_all();
                menu.append(item);
            }
        }
        queue_draw();
    }

    protected void on_state_changed(Wnck.WindowState changed, Wnck.WindowState state)
    {
        if (!window.needs_attention() && we_urgent) {
            we_urgent = false;
            if (source_id > 0) {
                remove_tick_callback(source_id);
                source_id = 0;
            }
            queue_draw();
            return;
        } else if (window.needs_attention() && !we_urgent) {
            we_urgent = true;
            should_fade_in = true;
            urg_opacity = DEFAULT_OPACITY;
            current_cycles = 0;
            source_id = add_tick_callback(on_tick);
        }
    }

    protected bool on_tick(Gtk.Widget widget, Gdk.FrameClock clock)
    {
        // Looks fine with 60hz. Might go nuts higher.
        var increment = 0.01;

        if (window == null) {
            urg_opacity = 0.0;
            we_urgent = false;
            return false;
        }

        if (should_fade_in) {
            urg_opacity += increment;
        } else {
            urg_opacity -= increment;
        }

        if (urg_opacity >= 1.0) {
            should_fade_in = false;
            urg_opacity = 1.0;
            current_cycles += 1;
        } else if (urg_opacity <= 0.0) {
            should_fade_in = true;
            urg_opacity = 0.0;
        }

        queue_draw();

        /* Stop flashing when we've fully cycled MAX_CYCLES */
        if (current_cycles >= MAX_CYCLES && urg_opacity >= 1.0) {
            return false;
        }

        return we_urgent;
    }

    public override bool draw(Cairo.Context cr)
    {
        if (!we_urgent) {
            return base.draw(cr);
        }

        /* Redundant right now but we might decide on something new in future. */
        int x = our_alloc.x;
        int y = our_alloc.y;
        int width = our_alloc.width;
        int height = our_alloc.height;

        Gdk.RGBA col = {};
        /* FIXME: I'M ON DRUGS */
        col.parse("#36689E");
        cr.set_source_rgba(col.red, col.green, col.blue, urg_opacity);
        cr.rectangle(x, y, width, height);
        cr.paint();

        return base.draw(cr);
    }

    public IconButton(Settings? settings, Wnck.Window? window, int size, DesktopAppInfo? ainfo)
    {
        this.settings = settings;

        image = new Gtk.Image();
        image.pixel_size = size;
        icon_size = size;
        add(image);

        this.window = window;
        relief = Gtk.ReliefStyle.NONE;
        this.ainfo = ainfo;

        // Replace styling with our own
        var st = get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.add_class(BUDGIE_STYLE_CLASS_BUTTON);
        size_allocate.connect(on_size_allocate);

        update_from_window();

        // Handle clicking, etc.
        button_release_event.connect(on_button_release);
    }

    /**
     * This is for minimize animations, etc.
     */
    protected void on_size_allocate(Gtk.Allocation alloc)
    {
        if (window == null) {
            return;
        }
        int x, y;
        var toplevel = get_toplevel();
        translate_coordinates(toplevel, 0, 0, out x, out y);
        toplevel.get_window().get_root_coords(x, y, out x, out y);
        window.set_icon_geometry(x, y, alloc.width, alloc.height);

        our_alloc = alloc;
    }

    /**
     * Update the icon
     */
    public virtual void update_icon()
    {
        if (window == null) {
            return;
        }

        unowned GLib.Icon? aicon = null;
        if (ainfo != null) {
            aicon = ainfo.get_icon();
        }

        if (DesktopHelper.has_derpy_icon(window) && aicon != null) {
            image.set_from_gicon(aicon, Gtk.IconSize.INVALID);
        } else {
            if (window.get_icon_is_fallback()) {
                if (ainfo != null && ainfo.get_icon() != null) {
                    image.set_from_gicon(ainfo.get_icon(), Gtk.IconSize.INVALID);
                } else {
                    image.set_from_pixbuf(window.get_icon());
                }
            } else {
                image.set_from_pixbuf(window.get_icon());
            }
        }
        image.pixel_size = icon_size;
    }

    /**
     * Either show the actions menu, or activate our window
     */
    public virtual bool on_button_release(Gdk.EventButton event)
    {
        var timestamp = Gtk.get_current_event_time();

        if (window != null) {
            if (this is /*Sparta*/ PinnedIconButton) {
                unpinnage.show();
                pinnage.hide();
            } else {
                unpinnage.hide();
                pinnage.show();
            }
        }

        if (ainfo == null) {
            unpinnage.hide();
            pinnage.hide();
            sep_item.hide();
        } else {
            if (sep_item != null) {
                sep_item.show();
            }
        }

        // Right click, i.e. actions menu
        if (event.button == 3) {
            menu.popup(null, null, null, event.button, timestamp);
            return true;
        }
        if (window == null) {
            return base.button_release_event(event);
        }

        // Normal left click, go handle the window
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

        return base.button_release_event(event);
    }
            
}

public class PinnedIconButton : IconButton
{
    public DesktopAppInfo app_info;
    protected unowned Gdk.AppLaunchContext? context;
    public string? id = null;
    private Gtk.Menu alt_menu;

    unowned Settings? settings;

    public PinnedIconButton(Settings settings, DesktopAppInfo info, int size, ref Gdk.AppLaunchContext context)
    {
        base(settings, null, size, info);
        this.app_info = info;
        this.settings = settings;

        this.context = context;
        set_tooltip_text("Launch %s".printf(info.get_display_name()));
        image.set_from_gicon(info.get_icon(), Gtk.IconSize.INVALID);

        alt_menu = new Gtk.Menu();
        var item = new Gtk.MenuItem.with_label("Unpin from panel");
        alt_menu.add(item);
        item.show_all();

        item.activate.connect(()=> {
            DesktopHelper.set_pinned(settings, this.app_info, false);
        });
    }

    protected override bool on_button_release(Gdk.EventButton event)
    {
        if (window == null)
        {
            if (event.button == 3) {
                // Expose our own unpin option
                alt_menu.popup(null, null, null, event.button, Gtk.get_current_event_time());
                return true;
            }
            if (event.button != 1) {
                return true;
            }
            /* Launch ourselves. */
            try {
                context.set_screen(get_screen());
                context.set_timestamp(event.time);
                var id = context.get_startup_notify_id(app_info, null);
                this.id = id;
                app_info.launch(null, this.context);
            } catch (Error e) {
                /* Animate a UFAILED image? */
                message(e.message);
            }
            return base.on_button_release(event);
        } else {
            return base.on_button_release(event);
        }
    }

    public override void update_icon()
    {
        if (window != null) {
            base.update_icon();
            return;
        }
        image.pixel_size = icon_size;
    }

    public void reset()
    {
        image.set_from_gicon(app_info.get_icon(), Gtk.IconSize.INVALID);
        set_tooltip_text("Launch %s".printf(app_info.get_display_name()));
        get_style_context().remove_class("running");
        set_active(false);
        // Actions menu
        menu.destroy();
        menu = null;
        window = null;
        id = null;
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
    protected DesktopHelper helper;

    private unowned IconButton? active_button;

    public string uuid { public set ; public get ; }

    public override Gtk.Widget? get_settings_ui()
    {
        return new IconTasklistSettings(this.get_applet_settings(uuid));
    }

    public override bool supports_settings()
    {
        return true;
    }

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
        var pinfo = helper.get_app_info_for_window(window);

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
            var btn = new IconButton(settings, window, icon_size, pinfo);
            button = btn;
            widget.pack_start(btn, false, false, 0);
        }
        buttons[window] = button;
        button.show_all();
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
            btn.destroy();
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

        helper = new DesktopHelper();

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

        settings = this.get_applet_settings(uuid);
        settings.changed.connect(on_settings_change);

        on_settings_change("pinned-launchers");
        on_settings_change("larger-icons");

        // Init wnck
        screen = Wnck.Screen.get_default();
        screen.window_opened.connect(window_opened);
        screen.window_closed.connect(window_closed);
        screen.active_window_changed.connect(active_window_changed);

        panel_size_changed.connect(on_panel_size_changed);

        get_style_context().add_class("icon-tasklist");

        add(main_layout);
        show_all();
    }

    void set_icons_size()
    {
        unowned Wnck.Window? btn_key = null;
        unowned string? str_key = null;
        unowned IconButton? val = null;
        unowned PinnedIconButton? pin_val = null;

        if (this.larger_icons) {
            icon_size = large_icons;
        } else {
            icon_size = small_icons;
        }
    
        Wnck.set_default_icon_size(icon_size);

        Idle.add(()=> {
            var iter = HashTableIter<Wnck.Window?,IconButton?>(buttons);
            while (iter.next(out btn_key, out val)) {
                val.icon_size = icon_size;
                val.update_icon();
            }

            var iter2 = HashTableIter<string?,PinnedIconButton?>(pin_buttons);
            while (iter2.next(out str_key, out pin_val)) {
                pin_val.icon_size = icon_size;
                pin_val.update_icon();
            }
            return false;
        });
    }

    int small_icons = 32;
    int large_icons = 32;
    bool larger_icons = false;

    void on_panel_size_changed(int panel, int icon, int small_icon)
    {
        this.small_icons = small_icon;
        this.large_icons = icon;

        set_icons_size();
    }


    protected void on_settings_change(string key)
    {
        if (key == "larger-icons") {
            this.larger_icons = settings.get_boolean(key);
            set_icons_size();
            return;
        } else if (key != "pinned-launchers") {
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
            var button = new PinnedIconButton(settings, info, icon_size, ref this.context);
            pin_buttons[desktopfile] = button;
            pinned.pack_start(button, false, false, 0);

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
                    btn.destroy();
                    buttons.remove(keyn);
                    buttons[keyn] = button;
                    button.update_from_window();
                    break;
                }
            }

            button.show_all();
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
                btn.destroy();
            } else {
                /* We need to move this fella.. */
                IconButton b2 = new IconButton(settings, btn.window, icon_size, (owned)btn.app_info);
                btn.destroy();
                widget.pack_start(b2, false, false, 0);
                buttons[b2.window]  = b2;
                b2.show_all();
            }
            removals += key_name;
        }
        foreach (string rkey in removals) {
            pin_buttons.remove(rkey);
        }

        for (int i=0; i<files.length; i++) {
            pinned.reorder_child(pin_buttons[files[i]], i);
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
