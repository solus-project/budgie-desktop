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

const double INACTIVE_OPACITY = 0.5;
const double ACTIVE_OPACITY = 1.0;

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


/**
 * Trivial helper for IconTasklist - i.e. desktop lookups
 */
public class DesktopHelper : Object
{

    Gee.HashMap<string?,string?> simpletons;
    Gee.HashMap<string?,string?> startupids;

    public DesktopHelper()
    {
        /* Initialize simpletons. */
        simpletons = new Gee.HashMap<string?,string?>(null,null,null);
        simpletons["google-chrome-stable"] = "google-chrome";
        simpletons["gnome-clocks"] = "org.gnome.clocks";
        simpletons["gnome-screenshot"] = "org.gnome.Screenshot";
        simpletons["nautilus"] = "org.gnome.Nautilus";

#if HAVE_GLIB240
        var monitor = AppInfoMonitor.get();
        monitor.changed.connect(()=> {
            startupids = null;
            reload_ids();
        });
#endif
        reload_ids();
    }

    void reload_ids()
    {
        startupids = new Gee.HashMap<string?,string?>(null,null,null);
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

    public static void set_pinned(DesktopAppInfo app_info, bool pinned)
    {
        Settings settings = new Settings("com.evolve-os.budgie.panel");
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

    public void update_from_window()
    {
        we_urgent = false;
        if (source_id > 0) {
            remove_tick_callback(source_id);
            source_id = 0;
        }

        if (window == null) {
            if (this is PinnedIconButton) {
                var p = this as PinnedIconButton;
                p.set_opacity(INACTIVE_OPACITY);
            }
            queue_draw();
            return;
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


        /* Opaque, due to being **active** */
        if (this is PinnedIconButton) {
            var p = this as PinnedIconButton;
            p.set_opacity(ACTIVE_OPACITY);
        }

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
            DesktopHelper.set_pinned(ainfo, true);
        });

        unpinnage.activate.connect(()=> {
            if (this is /*Sparta*/ PinnedIconButton) {
                var p = this as PinnedIconButton;
                DesktopHelper.set_pinned(p.app_info, false);
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
        col.parse("#36689E");
        cr.set_source_rgba(col.red, col.green, col.blue, urg_opacity);
        cr.rectangle(x, y, width, height);
        cr.paint();

        return base.draw(cr);
    }

    public IconButton(Wnck.Window? window, int size, DesktopAppInfo? ainfo)
    {
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

        if (window.get_icon_is_fallback()) {
            if (ainfo != null && ainfo.get_icon() != null) {
                image.set_from_gicon(ainfo.get_icon(), Gtk.IconSize.INVALID);
            } else {
                image.set_from_pixbuf(window.get_icon());
            }
        } else {
            image.set_from_pixbuf(window.get_icon());
        }
        image.pixel_size = icon_size;
    }

    /**
     * Either show the actions menu, or activate our window
     */
    public virtual bool on_button_release(Gdk.EventButton event)
    {
        var timestamp = Gtk.get_current_event_time();

        if (this is /*Sparta*/ PinnedIconButton) {
            unpinnage.show();
            pinnage.hide();
        } else {
            unpinnage.hide();
            pinnage.show();
        }

        if (ainfo == null) {
            unpinnage.hide();
            pinnage.hide();
            sep_item.hide();
        } else {
            sep_item.show();
        }

        // Right click, i.e. actions menu
        if (event.button == 3) {
            menu.popup(null, null, null, event.button, timestamp);
            return true;
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

        return true;
    }
            
}

public class PinnedIconButton : IconButton
{
    public DesktopAppInfo app_info;
    protected unowned Gdk.AppLaunchContext? context;
    public string? id = null;
    private Gtk.Menu alt_menu;

    public PinnedIconButton(DesktopAppInfo info, int size, ref Gdk.AppLaunchContext context)
    {
        base(null, size, info);
        this.app_info = info;

        this.context = context;
        set_tooltip_text("Launch %s".printf(info.get_display_name()));
        image.set_from_gicon(info.get_icon(), Gtk.IconSize.INVALID);

        set_opacity(INACTIVE_OPACITY);

        alt_menu = new Gtk.Menu();
        var item = new Gtk.MenuItem.with_label("Unpin from panel");
        alt_menu.add(item);
        item.show_all();

        item.activate.connect(()=> {
            DesktopHelper.set_pinned(this.app_info, false);
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
            return true;
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
        set_active(false);
        // Actions menu
        menu.destroy();
        menu = null;
        window = null;
        id = null;
        set_opacity(INACTIVE_OPACITY);
    }
}

public class IconTasklistApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new IconTasklistAppletImpl();
    }
}

public class IconTasklistAppletImpl : Budgie.Applet
{

    protected Gtk.Box widget;
    protected Gtk.Box main_layout;
    protected Gtk.Box pinned;

    protected Wnck.Screen screen;
    protected Gee.HashMap<Wnck.Window,IconButton> buttons;
    protected Gee.HashMap<string?,PinnedIconButton?> pin_buttons;
    protected int icon_size = 32;
    private Settings settings;

    protected Gdk.AppLaunchContext context;
    protected DesktopHelper helper;

    private unowned IconButton? active_button;
    Budgie.PanelPosition panel_position = Budgie.PanelPosition.BOTTOM;

    public override bool draw(Cairo.Context cr)
    {
        Gtk.Allocation alloc;
        Gtk.Allocation our_alloc;
        base.draw(cr);
        if (active_button == null) {
            return Gdk.EVENT_PROPAGATE;
        }

        get_allocation(out our_alloc);
        active_button.get_allocation(out alloc);
        var st = get_style_context();
        var col = st.get_border_color(get_state_flags());

        var height = 2;
        var y = alloc.height - height;
        var x = alloc.x - our_alloc.x;
        var width = alloc.width;

        switch (panel_position) {
            case Budgie.PanelPosition.TOP:
                y = 0;
                break;
            case Budgie.PanelPosition.LEFT:
                x = 0;
                y = alloc.y-our_alloc.y;
                width = height;
                height = alloc.height;
                break;
            case Budgie.PanelPosition.RIGHT:
                x = (our_alloc.x+alloc.width)-height;
                y = alloc.y-our_alloc.y;
                width = height;
                height = alloc.height;
                break;
            default:
                break;
        }

        cr.set_source_rgba(col.red, col.green, col.blue, col.alpha);
        cr.rectangle(x, y, width, height);
        cr.fill();

        return Gdk.EVENT_PROPAGATE;
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
            foreach (var pbtn in pin_buttons.values) {
                if (pbtn.id != null && startupid_match(pbtn.id, launch_id)) {
                    btn = pbtn;
                    break;
                }
            }
            if (btn != null) {
                btn.window = window;
                btn.update_from_window();
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
            var btn = new IconButton(window, icon_size, pinfo);
            button = btn;
            widget.pack_start(btn, false, false, 0);
        }
        buttons[window] = button;
        button.show_all();
    }

    protected void window_closed(Wnck.Window window)
    {
        IconButton? btn = null;
        if (!buttons.has_key(window)) {
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
        buttons.unset(window);
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
            if (buttons.has_key(previous_window)) {
                btn = buttons[previous_window];
                btn.set_active(false);
            } 
        }
        new_active = screen.get_active_window();
        if (new_active == null) {
            active_button = null;
            queue_draw();
            return;
        }
        if (!buttons.has_key(new_active)) {
            return;
        }
        btn = buttons[new_active];
        btn.set_active(true);
        active_button = btn;
        queue_draw();
    }

    public IconTasklistAppletImpl()
    {
        this.context = Gdk.Screen.get_default().get_display().get_app_launch_context();

        helper = new DesktopHelper();

        // Easy mapping :)
        buttons = new Gee.HashMap<Wnck.Window,IconButton>(null,null,null);
        pin_buttons = new Gee.HashMap<string?,PinnedIconButton?>(null,null,null);

        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        pinned = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        main_layout.pack_start(pinned, false, false, 0);
        pinned.set_property("margin-right", 10);

        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        main_layout.pack_start(widget, false, false, 0);

        settings = new Settings("com.evolve-os.budgie.panel");
        settings.changed.connect(on_settings_change);

        on_settings_change("pinned-launchers");

        // Init wnck
        screen = Wnck.Screen.get_default();
        screen.window_opened.connect(window_opened);
        screen.window_closed.connect(window_closed);
        screen.active_window_changed.connect(active_window_changed);

        icon_size_changed.connect((i,s)=> {
            icon_size = (int)i;
            Wnck.set_default_icon_size(icon_size);
            foreach (var btn in buttons.values) {
                Idle.add(()=>{
                    btn.icon_size = icon_size;
                    btn.update_icon();
                    return false;
                });
            }
            foreach (var btn in pin_buttons.values) {
                Idle.add(()=>{
                    btn.icon_size = icon_size;
                    btn.update_icon();
                    return false;
                });
            }
        });

        // Update orientation when parent panel does
        orientation_changed.connect((o)=> {
            main_layout.set_orientation(o);
            widget.set_orientation(o);
            pinned.set_orientation(o);
        });
        position_changed.connect((p) => {
            pinned.set_property("margin", 0);
            switch (p) {
                case Budgie.PanelPosition.LEFT:
                case Budgie.PanelPosition.RIGHT:
                    pinned.set_property("margin-bottom", 10);
                    break;
                default:
                    pinned.set_property("margin-right", 10);
                    break;
            }
            panel_position = p;
            queue_draw();
        });

        get_style_context().add_class("budgie-icon-tasklist");

        add(main_layout);
        show_all();
    }

    protected void on_settings_change(string key)
    {
        /* Don't care if its not launchers. */
        if (key != "pinned-launchers") {
            return;
        }
        string[] files = settings.get_strv(key);
        /* We don't actually remove anything >_> */
        foreach (string desktopfile in settings.get_strv(key)) {
            /* Ensure we don't have this fella already. */
            if (pin_buttons.has_key(desktopfile)) {
                continue;
            }
            var info = new DesktopAppInfo(desktopfile);
            if (info == null) {
                message("Invalid application! %s", desktopfile);
                continue;
            }
            var button = new PinnedIconButton(info, icon_size, ref this.context);
            pin_buttons[desktopfile] = button;
            pinned.pack_start(button, false, false, 0);

            // Do we already have an icon button for this?
            foreach (var keyn in buttons.keys) {
                var btn = buttons[keyn];
                if (btn.ainfo == null) {
                    continue;
                }
                if (btn.ainfo.get_id() == info.get_id() && btn.requested_pin) {
                    // Pinning an already active button.
                    button.window = btn.window;
                    // destroy old one
                    btn.destroy();
                    buttons.unset(keyn);
                    buttons[keyn] = button;
                    button.update_from_window();
                    break;
                }
            }

            button.show_all();
        }
        string[] removals = {};
        /* Conversely, remove ones which have been unset. */
        foreach (string key_name in pin_buttons.keys) {
            if (key_name in files) {
                continue;
            }
            /* We have a removal. */
            PinnedIconButton? btn = pin_buttons[key_name];
            if (btn.window == null) {
                btn.destroy();
            } else {
                /* We need to move this fella.. */
                IconButton b2 = new IconButton(btn.window, icon_size, (owned)btn.app_info);
                btn.destroy();
                widget.pack_start(b2, false, false, 0);
                buttons[b2.window]  = b2;
                b2.show_all();
            }
            removals += key_name;
        }
        foreach (string key_name in removals) {
            pin_buttons.unset(key_name);
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
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(IconTasklistApplet));
}
