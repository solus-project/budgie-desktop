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

namespace Arc {


public static const string MUTTER_EDGE_TILING  = "edge-tiling";
public static const string MUTTER_MODAL_ATTACH = "attach-modal-dialogs";
public static const string WM_SCHEMA           = "com.solus-project.arc-wm";

public static const bool CLUTTER_EVENT_PROPAGATE = false;
public static const bool CLUTTER_EVENT_STOP      = true;

public static const string RAVEN_DBUS_NAME        = "com.solus_project.arc.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/arc/Raven";

public static const string PANEL_DBUS_NAME        = "com.solus_project.arc.Panel";
public static const string PANEL_DBUS_OBJECT_PATH = "/com/solus_project/arc/Panel";

public enum PanelAction {
    NONE = 1 << 0,
    MENU = 1 << 1,
    MAX = 1 << 2
}

[DBus (name="com.solus_project.arc.Raven")]
public interface RavenRemote : Object
{
    public abstract async void Toggle() throws Error;
}

[DBus (name = "com.solus_project.arc.Panel")]
public interface PanelRemote : Object
{

    public abstract async void ActivateAction(int flags) throws Error;
}

public class ArcWM : Meta.Plugin
{
    static Meta.PluginInfo info;

    public bool use_animations { public set ; public get ; default = true; }
    public static string[]? old_args;
    public static bool wayland = false;

    public static bool gtk_available = true;

    static Clutter.Point PV_CENTER;
    static Clutter.Point PV_NORM;

    private Meta.BackgroundGroup? background_group;

    private Gtk.Menu? menu = null;
    private KeyboardManager? keyboard = null;

    Settings? settings = null;
    RavenRemote? raven_proxy = null;
    ShellShim? shim = null;
    PanelRemote? panel_proxy = null;
    WindowMenu? winmenu = null;

    static construct
    {
        info = Meta.PluginInfo() {
            name = "Arc WM",
            /*version = Arc.VERSION,*/
            version = "1",
            author = "Ikey Doherty",
            license = "GPL-2.0",
            description = "Arc Window Manager"
        };
        PV_CENTER = Clutter.Point.alloc();
        PV_CENTER.x = 0.5f;
        PV_CENTER.y = 0.5f;
        PV_NORM = Clutter.Point.alloc();
        PV_NORM.x = 0.0f;
        PV_NORM.y = 0.0f;
    }

    /* Hold onto our Raven proxy ref */
    void on_raven_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            raven_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to gain Raven proxy: %s", e.message);
        }
    }

    /* Obtain Panel manager */
    void on_panel_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            panel_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to get Panel proxy: %s", e.message);
        }
    }

    void lost_panel()
    {
        panel_proxy = null;
    }

    void has_panel()
    {
        if (panel_proxy == null) {
            Bus.get_proxy.begin<PanelRemote>(BusType.SESSION, PANEL_DBUS_NAME, PANEL_DBUS_OBJECT_PATH, 0, null, on_panel_get);
        }
    }

    /* Binding for toggle-raven activated */
    void on_raven_toggle(Meta.Display display, Meta.Screen screen,
                         Meta.Window? window, Clutter.KeyEvent? event,
                         Meta.KeyBinding binding)
    {
        if (raven_proxy == null) {
            warning("Raven does not appear to be running!");
            return;
        }
        try {
            raven_proxy.Toggle.begin();
        } catch (Error e) {
            warning("Unable to Toggle() Raven: %s", e.message);
        }
    }

    /* Set up the proxy when raven appears */
    void has_raven()
    {
        if (raven_proxy == null) {
            Bus.get_proxy.begin<RavenRemote>(BusType.SESSION, RAVEN_DBUS_NAME, RAVEN_DBUS_OBJECT_PATH, 0, null, on_raven_get);
        }
    }

    void lost_raven()
    {
        raven_proxy = null;
    }


    public override unowned Meta.PluginInfo? plugin_info() {
        return info;
    }

    void on_overlay_key()
    {
        if (panel_proxy == null) {
            return;
        }
        Idle.add(()=> {
            try {
                panel_proxy.ActivateAction.begin((int) PanelAction.MENU);
            } catch (Error e) {
                message("Unable to ActivateAction for menu: %s", e.message);
            }
            return false;
        });
    }


    void launch_menu(Meta.Display display, Meta.Screen screen,
                     Meta.Window? window, Clutter.KeyEvent? event,
                     Meta.KeyBinding binding)
    {
        on_overlay_key();
    }

    void on_dialog_closed(GLib.Pid pid, int status)
    {
        bool ok = false;
        try {
            ok = Process.check_exit_status(status);
        } catch (Error e) {
        }
        this.complete_display_change(ok);
    }

    public override void confirm_display_change()
    {
        GLib.Pid pid = Meta.Util.show_dialog("--question",
                          "Does the display look OK?",
                          "20",
                          null,
                          "_Keep This Configuration",
                          "_Restore Previous Configuration",
                          "preferences-desktop-display",
                          0,
                          null, null);

        ChildWatch.add(pid, on_dialog_closed);
    }

    public override void start()
    {
        var screen = this.get_screen();
        var screen_group = Meta.Compositor.get_window_group_for_screen(screen);
        var stage = Meta.Compositor.get_stage_for_screen(screen);

        var display = screen.get_display();

        Meta.Prefs.override_preference_schema(MUTTER_EDGE_TILING, WM_SCHEMA);
        Meta.Prefs.override_preference_schema(MUTTER_MODAL_ATTACH, WM_SCHEMA);

        /* Follow GTK's policy on animations */
        if (gtk_available) {
            var settings = Gtk.Settings.get_default();
            settings.bind_property("gtk-enable-animations", this, "use-animations");
            winmenu = new WindowMenu();
        }

        settings = new Settings(WM_SCHEMA);
        /* Custom keybindings */
        display.add_keybinding("toggle-raven", settings, Meta.KeyBindingFlags.NONE, on_raven_toggle);
        display.overlay_key.connect(on_overlay_key);

        /* Hook up Raven handler.. */
        Bus.watch_name(BusType.SESSION, RAVEN_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_raven, lost_raven);

        Bus.watch_name(BusType.SESSION, PANEL_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_panel, lost_panel);



        Meta.KeyBinding.set_custom_handler("panel-main-menu", launch_menu);

        shim = new ShellShim(this);
        shim.serve();

        background_group = new Meta.BackgroundGroup();
        background_group.set_reactive(true);
        screen_group.insert_child_below(background_group, null);

        screen.monitors_changed.connect(on_monitors_changed);
        on_monitors_changed(screen);

        background_group.show();
        screen_group.show();
        stage.show();

        if (wayland && !gtk_available) {
            unowned string[] args = ArcWM.old_args;
            if (Gtk.init_check(ref args)) {
                ArcWM.gtk_available = true;
                message("Got GTK+ now");
            } else {
                message("Still no GTK+");
            }
        }

        if (ArcWM.gtk_available) {
            init_menu();
        }

        keyboard = new KeyboardManager(this);
        keyboard.hook_extra();
    }

    public override void show_window_menu(Meta.Window window, Meta.WindowMenuType type, int x, int y)
    {
        if (type != Meta.WindowMenuType.WM) {
            return;
        }

        if (winmenu == null) {
            return;
        }
        Timeout.add(100, ()=> {
            winmenu.meta_window = window;
            winmenu.popup(null, null, null, 3, Gdk.CURRENT_TIME);
            return false;
        });
    }
        
    bool on_button_release(Clutter.ButtonEvent? event)
    {
        if (event.button != 3) {
            return CLUTTER_EVENT_PROPAGATE;
        }
        if (menu.get_visible()) {
            menu.hide();
        } else {
            menu.popup(null, null, null, event.button, event.time);
        }
        return CLUTTER_EVENT_STOP;
    }

    void on_monitors_changed(Meta.Screen? screen)
    {
        background_group.destroy_all_children();

        for (int i = 0; i < screen.get_n_monitors(); i++) {
            var actor = new ArcBackground(screen, i);
            background_group.add_child(actor);
        }
    }

    void background_activate()
    {
        try {
            var info = new DesktopAppInfo("gnome-background-panel.desktop");
            if (info != null) {
                info.launch(null, null);
            }
        } catch (Error e) {
            warning("Unable to launch gnome-background-panel.desktop: %s", e.message);
        }
    }

    void settings_activate()
    {
        try {
            var info = new DesktopAppInfo("gnome-control-center.desktop");
            if (info != null) {
                info.launch(null, null);
            }
        } catch (Error e) {
            warning("Unable to launch gnome-control-center.desktop: %s", e.message);
        }
    }

    void init_menu()
    {
        menu = new Gtk.Menu();
        menu.show();
        var item = new Gtk.MenuItem.with_label(_("Change background\u2026"));
        item.activate.connect(background_activate);
        item.show();
        menu.append(item);

        var sep = new Gtk.SeparatorMenuItem();
        sep.show();
        menu.append(sep);

        item = new Gtk.MenuItem.with_label(_("Settings"));
        item.activate.connect(settings_activate);
        item.show();
        menu.append(item);

        this.background_group.button_release_event.connect(on_button_release);
    }

    static const int MAP_TIMEOUT  = 170;
    static const float MAP_SCALE  = 0.8f;
    static const float NOTIFICATION_MAP_SCALE_X  = 0.5f;
    static const float NOTIFICATION_MAP_SCALE_Y  = 0.8f;
    static const int FADE_TIMEOUT = 165;

    void map_done(Clutter.Actor? actor)
    {
        actor.remove_all_transitions();
        SignalHandler.disconnect_by_func(actor, (void*)map_done, this);
        actor.set("pivot-point", PV_NORM);
        this.map_completed(actor as Meta.WindowActor);
    }

    void notification_map_done(Clutter.Actor? actor)
    {
        actor.remove_all_transitions();
        SignalHandler.disconnect_by_func(actor, (void*)map_done, this);
        actor.set("pivot-point", PV_NORM);
        this.map_completed(actor as Meta.WindowActor);
    }

    public override void map(Meta.WindowActor actor)
    {
        Meta.Window? window = actor.get_meta_window();

        if (!use_animations) {
            this.map_completed(actor);
            return;
        }

        switch (window.get_window_type()) {
            case Meta.WindowType.POPUP_MENU:
            case Meta.WindowType.DROPDOWN_MENU:
            case Meta.WindowType.MENU:
                actor.opacity = 0;
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
                actor.set_easing_duration(MAP_TIMEOUT);
                actor.transitions_completed.connect(map_done);

                actor.opacity = 255;
                actor.restore_easing_state();
                break;
            case Meta.WindowType.NOTIFICATION:
                actor.set("opacity", 0, "scale-x", NOTIFICATION_MAP_SCALE_X, "scale-y", NOTIFICATION_MAP_SCALE_Y,
                    "pivot-point", PV_CENTER);
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUART);
                actor.set_easing_duration(MAP_TIMEOUT);
                actor.transitions_completed.connect(notification_map_done);

                actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255);
                actor.restore_easing_state();
                break;
            case Meta.WindowType.NORMAL:
            case Meta.WindowType.DIALOG:
            case Meta.WindowType.MODAL_DIALOG:
                actor.set("opacity", 0, "scale-x", MAP_SCALE, "scale-y", MAP_SCALE,
                    "pivot-point", PV_CENTER);
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
                actor.set_easing_duration(MAP_TIMEOUT);
                actor.transitions_completed.connect(map_done);

                actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255);
                actor.restore_easing_state();
                break;
            default:
                this.map_completed(actor);
                break;
        }
    }

    void minimize_done(Clutter.Actor? actor)
    {
        actor.remove_all_transitions();
        SignalHandler.disconnect_by_func(actor, (void*)minimize_done, this);
        actor.set("pivot-point", PV_NORM, "opacity", 255, "scale-x", 1.0, "scale-y", 1.0);
        actor.hide();
        this.minimize_completed(actor as Meta.WindowActor);
    }

    static const int MINIMIZE_TIMEOUT = 200;

    public override void minimize(Meta.WindowActor actor)
    {
        if (!this.use_animations) {
            this.minimize_completed(actor);
            return;
        }
        Meta.Rectangle icon;
        Meta.Window? window = actor.get_meta_window();

        if (window.get_window_type() != Meta.WindowType.NORMAL) {
            this.minimize_completed(actor);
            return;
        }

        if (!window.get_icon_geometry(out icon)) {
            icon.x = 0;
            icon.y = 0;
        }

        actor.set("pivot-point", PV_CENTER);
        actor.save_easing_state();
        actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
        actor.set_easing_duration(MINIMIZE_TIMEOUT);
        actor.transitions_completed.connect(minimize_done);

        actor.set("opacity", 0, "x", (double)icon.x, "y", (double)icon.y, "scale-x", 0.0, "scale-y", 0.0);
        actor.restore_easing_state();
    }

    void destroy_done(Clutter.Actor? actor)
    {
        actor.remove_all_transitions();
        SignalHandler.disconnect_by_func(actor, (void*)destroy_done, this);
        this.destroy_completed(actor as Meta.WindowActor);
    }

    static const int DESTROY_TIMEOUT  = 170;
    static const double DESTROY_SCALE = 0.6;

    public override void destroy(Meta.WindowActor actor)
    {
        if (!this.use_animations) {
            this.destroy_completed(actor);
            return;
        }

        Meta.Window? window = actor.get_meta_window();
        actor.remove_all_transitions();

        switch (window.get_window_type()) {
            case Meta.WindowType.NOTIFICATION:
            case Meta.WindowType.NORMAL:
            case Meta.WindowType.DIALOG:
            case Meta.WindowType.MODAL_DIALOG:
                actor.set("pivot-point", PV_CENTER);
                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
                actor.set_easing_duration(DESTROY_TIMEOUT);
                actor.transitions_completed.connect(destroy_done);

                actor.set("scale-x", DESTROY_SCALE, "scale-y", DESTROY_SCALE, "opacity", 0);
                actor.restore_easing_state();
                break;
            case Meta.WindowType.MENU:
                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
                actor.transitions_completed.connect(destroy_done);

                actor.set("opacity", 0);
                actor.restore_easing_state();
                break;
            default:
                this.destroy_completed(actor);
                break;
        }
    }
}

} /* End namespace */
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
