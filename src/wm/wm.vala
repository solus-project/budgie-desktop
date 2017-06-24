/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {


public const string MUTTER_EDGE_TILING  = "edge-tiling";
public const string MUTTER_MODAL_ATTACH = "attach-modal-dialogs";
public const string MUTTER_BUTTON_LAYOUT = "button-layout";
public const string WM_FORCE_UNREDIRECT = "force-unredirect";
public const string WM_SCHEMA           = "com.solus-project.budgie-wm";

public const bool CLUTTER_EVENT_PROPAGATE = false;
public const bool CLUTTER_EVENT_STOP      = true;

public const string RAVEN_DBUS_NAME        = "org.budgie_desktop.Raven";
public const string RAVEN_DBUS_OBJECT_PATH = "/org/budgie_desktop/Raven";

public const string PANEL_DBUS_NAME        = "org.budgie_desktop.Panel";
public const string PANEL_DBUS_OBJECT_PATH = "/org/budgie_desktop/Panel";

public const string LOGIND_DBUS_NAME        = "org.freedesktop.login1";
public const string LOGIND_DBUS_OBJECT_PATH = "/org/freedesktop/login1";

/** Menu management */
public const string MENU_DBUS_NAME        = "org.budgie_desktop.MenuManager";
public const string MENU_DBUS_OBJECT_PATH = "/org/budgie_desktop/MenuManager";

public const string SWITCHER_DBUS_NAME        = "org.budgie_desktop.TabSwitcher";
public const string SWITCHER_DBUS_OBJECT_PATH = "/org/budgie_desktop/TabSwitcher";

[Flags]
public enum PanelAction {
    NONE = 1 << 0,
    MENU = 1 << 1,
    MAX = 1 << 2
}

public enum AnimationState {
    MAP         = 1 << 0,
    MINIMIZE    = 1 << 1,
    UNMINIMIZE  = 1 << 2,
    DESTROY     = 1 << 3
}

public class ScreenTilePreview : Clutter.Actor
{

    public Meta.Rectangle tile_rect;

    construct {
        set_background_color(Clutter.Color.get_static(Clutter.StaticColor.SKY_BLUE));
        set_opacity(100);

        tile_rect = Meta.Rectangle();
    }
}


[DBus (name="org.budgie_desktop.Raven")]
public interface RavenRemote : Object
{
    public abstract bool GetExpanded() throws Error;
    public abstract async void Toggle() throws Error;
    public abstract async void ToggleNotificationsView() throws Error;
    public abstract async void ToggleAppletView() throws Error;
    public abstract async void Dismiss() throws Error;
}

[DBus (name = "org.budgie_desktop.Panel")]
public interface PanelRemote : Object
{

    public abstract async void ActivateAction(int flags) throws Error;
}

[DBus (name = "org.freedesktop.login1.Manager")]
public interface LoginDRemote : GLib.Object
{
    public signal void PrepareForSleep(bool suspending);
}

/**
 * Allows us to invoke desktop menus without directly using GTK+ ourselves
 */
[DBus (name = "org.budgie_desktop.MenuManager")]
public interface MenuManager: GLib.Object
{
    public abstract async void ShowDesktopMenu(uint button, uint32 timestamp) throws Error;
    public abstract async void ShowWindowMenu(uint32 xid, uint button, uint32 timestamp) throws Error;
}

/**
 * Allows us to display the tab switcher without Gtk
 */
[DBus (name = "org.budgie_desktop.TabSwitcher")]
public interface Switcher: GLib.Object
{
    public abstract async void PassItem(uint32 xid, uint32 timestamp) throws Error;
    public abstract async void ShowSwitcher(uint32 curr_xid) throws Error;
    public abstract async void StopSwitcher() throws Error;
}

[CompactClass]
class MinimizeData {
    public double scale_x;
    public double scale_y;
    public double place_x;
    public double place_y;
    public double old_x;
    public double old_y;
}

public class BudgieWM : Meta.Plugin
{
    static Meta.PluginInfo info;

    public bool use_animations { public set ; public get ; default = true; }
    public static string[]? old_args;
    public static bool wayland = false;

    static Clutter.Point PV_CENTER;
    static Clutter.Point PV_NORM;

    private Meta.BackgroundGroup? background_group;

    private KeyboardManager? keyboard = null;

    Settings? settings = null;
    RavenRemote? raven_proxy = null;
    ShellShim? shim = null;
    BudgieWMDBUS? focus_interface = null;
    PanelRemote? panel_proxy = null;
    LoginDRemote? logind_proxy = null;
    MenuManager? menu_proxy = null;
    Switcher? switcher_proxy = null;

    private bool force_unredirect = false;

    HashTable<Meta.WindowActor?,AnimationState?> state_map;

    static construct
    {
        info = Meta.PluginInfo() {
            name = "Budgie WM",
            version = Budgie.VERSION,
            author = "Ikey Doherty",
            license = "GPL-2.0",
            description = "Budgie Window Manager"
        };
        PV_CENTER = Clutter.Point.alloc();
        PV_CENTER.x = 0.5f;
        PV_CENTER.y = 0.5f;
        PV_NORM = Clutter.Point.alloc();
        PV_NORM.x = 0.0f;
        PV_NORM.y = 0.0f;
    }

    /* TODO: Make this support BSD, etc! */
    bool have_logind()
    {
        return FileUtils.test("/run/systemd/seats", FileTest.EXISTS);
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

    /* Obtain Menu manager */
    void on_menu_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            menu_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to get Menu proxy: %s", e.message);
        }
    }

    void lost_menu()
    {
        menu_proxy = null;
    }

    void has_menu()
    {
        if (menu_proxy == null) {
            Bus.get_proxy.begin<MenuManager>(BusType.SESSION, MENU_DBUS_NAME, MENU_DBUS_OBJECT_PATH, 0, null, on_menu_get);
        }
    }

    /* Obtain login manager */
    void on_logind_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            logind_proxy = Bus.get_proxy.end(res);
            if (logind_proxy == null) {
                return;
            }
            if (this.is_nvidia()) {
                logind_proxy.PrepareForSleep.connect(prepare_for_sleep);
            }
        } catch (Error e) {
            warning("Failed to get LoginD proxy: %s", e.message);
        }
    }

    /* Kudos to gnome-shell guys here: https://bugzilla.gnome.org/show_bug.cgi?id=739178 */
    void prepare_for_sleep(bool suspending)
    {
        if (suspending) {
            return;
        }
        Meta.Background.refresh_all();
    }

    void get_logind()
    {
        if (logind_proxy == null) {
            Bus.get_proxy.begin<LoginDRemote>(BusType.SYSTEM, LOGIND_DBUS_NAME, LOGIND_DBUS_OBJECT_PATH, 0, null, on_logind_get);
        }
    }

    void lost_switcher()
    {
        switcher_proxy = null;
    }

    void on_swicher_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            switcher_proxy = Bus.get_proxy.end(res);
        } catch (Error e) {
            warning("Failed to get Switcher proxy: %s", e.message);
        }
    }
    void has_switcher()
    {
        if(switcher_proxy == null) {
            Bus.get_proxy.begin<Switcher>(BusType.SESSION, SWITCHER_DBUS_NAME, SWITCHER_DBUS_OBJECT_PATH, 0, null, on_swicher_get);
        }
    }

    /* Binding for toggle-raven activated */
    void on_raven_main_toggle(Meta.Display display, Meta.Screen screen,
                              Meta.Window? window, Clutter.KeyEvent? event,
                              Meta.KeyBinding binding)
    {
        if (raven_proxy == null) {
            warning("Raven does not appear to be running!");
            return;
        }
        try {
            raven_proxy.ToggleAppletView.begin();
        } catch (Error e) {
            warning("Unable to ToggleAppletView() Raven: %s", e.message);
        }
    }

    /* Binding for toggle-notifications activated */
    void on_raven_notification_toggle(Meta.Display display, Meta.Screen screen,
                                      Meta.Window? window, Clutter.KeyEvent? event,
                                      Meta.KeyBinding binding)
    {
        if (raven_proxy == null) {
            warning("Raven does not appear to be running!");
            return;
        }
        try {
            raven_proxy.ToggleNotificationsView.begin();
        } catch (Error e) {
            warning("Unable to ToggleNotificationsView() Raven: %s", e.message);
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

    void launch_rundialog(Meta.Display display, Meta.Screen screen,
                            Meta.Window? window, Clutter.KeyEvent? event,
                            Meta.KeyBinding binding)
    {
        try {
            Process.spawn_command_line_async("budgie-run-dialog");
        } catch (Error e) {}
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

    delegate unowned string GlQueryFunc(uint id);
    static const uint GL_VENDOR = 0x1F00;

    private bool is_nvidia()
    {
        var ptr = (GlQueryFunc)Cogl.get_proc_address("glGetString");

        if (ptr == null) {
            return false;
        }

        unowned string? ret = ptr(GL_VENDOR);
        if (ret != null && "NVIDIA Corporation" in ret) {
            return true;
        }
        return false;
    }

    public override void start()
    {
        var screen = this.get_screen();
        var screen_group = Meta.Compositor.get_window_group_for_screen(screen);
        var stage = Meta.Compositor.get_stage_for_screen(screen);

        var display = screen.get_display();

        state_map = new HashTable<Meta.WindowActor?,AnimationState?>(GLib.direct_hash, GLib.direct_equal);

        Meta.Prefs.override_preference_schema(MUTTER_EDGE_TILING, WM_SCHEMA);
        Meta.Prefs.override_preference_schema(MUTTER_MODAL_ATTACH, WM_SCHEMA);
        Meta.Prefs.override_preference_schema(MUTTER_BUTTON_LAYOUT, WM_SCHEMA);

        settings = new Settings(WM_SCHEMA);
        this.settings.changed.connect(this.on_wm_schema_changed);
        this.on_wm_schema_changed(WM_FORCE_UNREDIRECT);

        /* Custom keybindings */
        display.add_keybinding("toggle-raven", settings, Meta.KeyBindingFlags.NONE, on_raven_main_toggle);
        display.add_keybinding("toggle-notifications", settings, Meta.KeyBindingFlags.NONE, on_raven_notification_toggle);
        display.overlay_key.connect(on_overlay_key);

        /* Hook up Raven handler.. */
        Bus.watch_name(BusType.SESSION, RAVEN_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_raven, lost_raven);

        /* Panel manager */
        Bus.watch_name(BusType.SESSION, PANEL_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_panel, lost_panel);

        /* Menu manager */
        Bus.watch_name(BusType.SESSION, MENU_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_menu, lost_menu);

        /* TabSwitcher */
        Bus.watch_name(BusType.SESSION, SWITCHER_DBUS_NAME, BusNameWatcherFlags.NONE,
            has_switcher, lost_switcher);

        /* Keep an eye out for systemd stuffs */
        if (have_logind()) {
            get_logind();
        }

        Meta.KeyBinding.set_custom_handler("panel-main-menu", launch_menu);
        Meta.KeyBinding.set_custom_handler("panel-run-dialog", launch_rundialog);
        Meta.KeyBinding.set_custom_handler("switch-windows", switch_windows);
        Meta.KeyBinding.set_custom_handler("switch-windows-backward", switch_windows_backward);
        Meta.KeyBinding.set_custom_handler("switch-applications", switch_windows);
        Meta.KeyBinding.set_custom_handler("switch-applications-backward", switch_windows_backward);

        shim = new ShellShim(this);
        shim.serve();

        focus_interface = new BudgieWMDBUS(this);
        focus_interface.serve();

        background_group = new Meta.BackgroundGroup();
        background_group.set_reactive(true);
        screen_group.insert_child_below(background_group, null);
        background_group.button_release_event.connect(on_background_click);

        screen.monitors_changed.connect(on_monitors_changed);
        on_monitors_changed(screen);

        background_group.show();
        screen_group.show();
        stage.show();

        keyboard = new KeyboardManager(this);
        keyboard.hook_extra();
    }

    /**
     * Launch menu manager with our wallpaper
     */
    private bool on_background_click(Clutter.ButtonEvent? event)
    {
        if (event.button == 1) {
            this.dismiss_raven();
        } else if (event.button == 3) {
            if (menu_proxy == null) {
                return CLUTTER_EVENT_STOP;
            }
            try {
                menu_proxy.ShowDesktopMenu.begin(3, 0);
            } catch (Error e) {
                message("Error invoking MenuManager: %s", e.message);
            }
        } else {
            return CLUTTER_EVENT_PROPAGATE;
        }

        return CLUTTER_EVENT_STOP;
    }

    private void on_wm_schema_changed(string key)
    {
        if (key != WM_FORCE_UNREDIRECT) {
            return;
        }
        bool enab = this.settings.get_boolean(key);
        if (enab == this.force_unredirect) {
            return;
        }

        var screen = this.get_screen();
        if (enab) {
            Meta.Util.enable_unredirect_for_screen(screen);
        } else {
            Meta.Util.disable_unredirect_for_screen(screen);
        }
        this.force_unredirect = enab;
    }

    public override void show_window_menu(Meta.Window window, Meta.WindowMenuType type, int x, int y)
    {
        if (type != Meta.WindowMenuType.WM) {
            return;
        }
        if (menu_proxy == null) {
            return;
        }
        Timeout.add(100, ()=> {
            uint32 xid = (uint32)window.get_xwindow();
            try {
                menu_proxy.ShowWindowMenu.begin(xid, 3, 0);
            } catch (Error e) {
                message("Error invoking MenuManager: %s", e.message);
            }
            return false;
        });
    }

    /* Dismiss raven from view. Consider in future tracking the visible
     * state
     */
    void dismiss_raven()
    {
        if (raven_proxy != null) {
            raven_proxy.Dismiss.begin();
        }
    }

    void on_monitors_changed(Meta.Screen? screen)
    {
        background_group.destroy_all_children();

        for (int i = 0; i < screen.get_n_monitors(); i++) {
            var actor = new BudgieBackground(screen, i);
            background_group.add_child(actor);
        }
    }

    static const int MAP_TIMEOUT  = 170;
    static const int MENU_MAP_TIMEOUT = 120;
    static const float MAP_SCALE  = 0.8f;
    static const float MENU_MAP_SCALE_X = 0.98f;
    static const float MENU_MAP_SCALE_Y = 0.95f;
    static const float NOTIFICATION_MAP_SCALE_X  = 0.5f;
    static const float NOTIFICATION_MAP_SCALE_Y  = 0.8f;
    static const int FADE_TIMEOUT = 165;

    void finalize_animations(Meta.WindowActor? actor)
    {
        if (!state_map.contains(actor)) {
            return;
        }

        actor.remove_all_transitions();

        unowned AnimationState? state = state_map.lookup(actor);
        switch (state) {
            case AnimationState.MAP:
                actor.set("pivot-point", PV_NORM, "opacity", 255U);
                map_completed(actor);
                break;
            case AnimationState.DESTROY:
                destroy_completed(actor);
                break;
            case AnimationState.MINIMIZE:
                actor.set("pivot-point", PV_NORM, "opacity", 255U, "scale-x", 1.0, "scale-y", 1.0);
                actor.hide();
                minimize_completed(actor);
                break;
            case AnimationState.UNMINIMIZE:
                actor.set("pivot-point", PV_NORM, "opacity", 255U, "scale-x", 1.0, "scale-y", 1.0);
                unminimize_completed(actor);
                break;
            default:
                break;
        }
        state_map.remove(actor);
    }

    void map_done(Clutter.Actor? actor)
    {
        SignalHandler.disconnect_by_func(actor, (void*)map_done, this);
        finalize_animations(actor as Meta.WindowActor);
    }

    void notification_map_done(Clutter.Actor? actor)
    {
        SignalHandler.disconnect_by_func(actor, (void*)notification_map_done, this);
        finalize_animations(actor as Meta.WindowActor);
    }

    private unowned Meta.Window? focused_window = null;

    /**
     * Store the focused window
     */
    public void store_focused()
    {
        var workspace = get_screen().get_active_workspace();
        foreach (var window in workspace.list_windows()) {
            if (window.has_focus()) {
                focused_window = window;
                break;
            }
        }
    }

    /**
     * Restore the focused window
     */
    public void restore_focused()
    {
        if (focused_window == null) {
            return;
        }
        focused_window.focus(get_screen().get_display().get_current_time());
        focused_window = null;
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
                actor.set("opacity", 0U, "scale-x", MENU_MAP_SCALE_X, "scale-y", MENU_MAP_SCALE_Y,
                    "pivot-point", PV_CENTER);
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_CIRC);
                actor.set_easing_duration(MENU_MAP_TIMEOUT);

                actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255U);
                break;
                break;
            case Meta.WindowType.NOTIFICATION:
                actor.set("opacity", 0U, "scale-x", NOTIFICATION_MAP_SCALE_X, "scale-y", NOTIFICATION_MAP_SCALE_Y,
                    "pivot-point", PV_CENTER);
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUART);
                actor.set_easing_duration(MAP_TIMEOUT);

                actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255U);
                break;
            case Meta.WindowType.NORMAL:
            case Meta.WindowType.DIALOG:
            case Meta.WindowType.MODAL_DIALOG:
                actor.set("opacity", 0U, "scale-x", MAP_SCALE, "scale-y", MAP_SCALE,
                    "pivot-point", PV_CENTER);
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_CIRC);
                actor.set_easing_duration(MAP_TIMEOUT);

                actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255U);
                break;
            default:
                this.map_completed(actor);
                return;
        }

        actor.transitions_completed.connect(map_done);
        state_map.insert(actor, AnimationState.MAP);
        actor.restore_easing_state();
    }

    void minimize_done(Clutter.Actor? actor)
    {
        SignalHandler.disconnect_by_func(actor, (void*)minimize_done, this);
        finalize_animations(actor as Meta.WindowActor);
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

        finalize_animations(actor);

        state_map.insert(actor, AnimationState.MINIMIZE);
        actor.save_easing_state();
        actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
        actor.set_easing_duration(MINIMIZE_TIMEOUT);
        actor.transitions_completed.connect(minimize_done);

        /* Save the minimize state for later restoration */
        MinimizeData d = new MinimizeData();
        d.scale_x = (double)(icon.width / actor.width);
        d.scale_y = (double)(icon.height / actor.height);
        d.place_x = (double)icon.x;
        d.place_y = (double)icon.y;
        d.old_x = actor.x;
        d.old_y = actor.y;

        actor.set_data("_minimize_data", d);
        actor.set("opacity", 0U, "scale-gravity", Clutter.Gravity.NORTH_WEST,
                  "x", d.place_x, "y", d.place_y, "scale-x",
                  d.scale_x, "scale-y", d.scale_y);
        actor.restore_easing_state();
    }

    /**
     * Unminimize now done
     */
    void unminimize_done(Clutter.Actor? actor)
    {
        SignalHandler.disconnect_by_func(actor, (void*)unminimize_done, this);
        finalize_animations(actor as Meta.WindowActor);
    }

    /**
     * Handle unminimize animation
     */
    public override void unminimize(Meta.WindowActor actor)
    {
        if (!this.use_animations) {
            this.unminimize_completed(actor);
            return;
        }

        MinimizeData? d = actor.get_data("_minimize_data");
        if (d == null) {
            this.unminimize_completed(actor);
            return;
        }

        finalize_animations(actor);

        actor.set("opacity", 0U, "scale-gravity", Clutter.Gravity.NORTH_WEST,
                  "x", d.place_x, "y", d.place_y, "scale-x",
                  d.scale_x, "scale-y", d.scale_y);

        actor.show();

        actor.save_easing_state();
        actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUART);
        actor.set_easing_duration(MINIMIZE_TIMEOUT);

        actor.set("scale-x", 1.0, "scale-y", 1.0, "opacity", 255U,
                  "x", d.old_x, "y", d.old_y);

        actor.transitions_completed.connect(unminimize_done);
        state_map.insert(actor, AnimationState.UNMINIMIZE);
        actor.restore_easing_state();

        actor.set_data("_minimize_data", null);
    }

    void destroy_done(Clutter.Actor? actor)
    {
        SignalHandler.disconnect_by_func(actor, (void*)destroy_done, this);
        finalize_animations(actor as Meta.WindowActor);
    }

    static const int DESTROY_TIMEOUT  = 170;
    static const double DESTROY_SCALE = 0.6;

    public override void destroy(Meta.WindowActor actor)
    {
        Meta.Window? window = actor.get_meta_window();

        if (focused_window == window) {
            focused_window = null;
        }

        if (!this.use_animations) {
            this.destroy_completed(actor);
            return;
        }

        finalize_animations(actor);

        switch (window.get_window_type()) {
            case Meta.WindowType.NOTIFICATION:
            case Meta.WindowType.NORMAL:
            case Meta.WindowType.DIALOG:
            case Meta.WindowType.MODAL_DIALOG:
                actor.set("pivot-point", PV_CENTER);
                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
                actor.set_easing_duration(DESTROY_TIMEOUT);

                actor.set("scale-x", DESTROY_SCALE, "scale-y", DESTROY_SCALE, "opacity", 0U);
                break;
            case Meta.WindowType.MENU:
                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);

                actor.set("opacity", 0U);
                break;
            default:
                this.destroy_completed(actor);
                return;
        }

        actor.transitions_completed.connect(destroy_done);
        state_map.insert(actor, AnimationState.DESTROY);
        actor.restore_easing_state();
    }

    private ScreenTilePreview? tile_preview = null;
    private uint8? default_tile_opacity = null;

    /* Ported from old budgie-wm, in turn ported from Mutter's default plugin */
    public override void show_tile_preview(Meta.Window window, Meta.Rectangle tile_rect, int tile_monitor_num)
    {
        var screen = this.get_screen();

        if (this.tile_preview == null) {
            this.tile_preview = new ScreenTilePreview();
            this.tile_preview.transitions_completed.connect(tile_preview_transition_complete);

            var screen_group = Meta.Compositor.get_window_group_for_screen(screen);
            screen_group.add_child(this.tile_preview);

            default_tile_opacity = this.tile_preview.get_opacity();
        }

        if (tile_preview.visible &&
            tile_preview.tile_rect.x == tile_rect.x &&
            tile_preview.tile_rect.y == tile_rect.y &&
            tile_preview.tile_rect.width == tile_rect.width &&
            tile_preview.tile_rect.height == tile_rect.height)
        {
            return;
        }

        var win_actor = window.get_compositor_private() as Clutter.Actor;

        tile_preview.remove_all_transitions();
        tile_preview.set_position(win_actor.x, win_actor.y);
        tile_preview.set_size(win_actor.width, win_actor.height);
        tile_preview.set_opacity(default_tile_opacity);
        tile_preview.set("scale-x", NOTIFICATION_MAP_SCALE_X, "scale-y", NOTIFICATION_MAP_SCALE_Y,
            "pivot-point", PV_CENTER);

        tile_preview.lower(win_actor);
        tile_preview.tile_rect = tile_rect;

        tile_preview.show();

        tile_preview.save_easing_state();
        tile_preview.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
        tile_preview.set_easing_duration(MAP_TIMEOUT);

        tile_preview.set_position(tile_rect.x, tile_rect.y);
        tile_preview.set_size(tile_rect.width, tile_rect.height);

        tile_preview.set("scale-x", 1.0, "scale-y", 1.0);
        tile_preview.restore_easing_state();

    }

    public override void hide_tile_preview()
    {
        if (tile_preview != null) {
            tile_preview.remove_all_transitions();
            tile_preview.save_easing_state();
            tile_preview.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
            tile_preview.set_easing_duration(FADE_TIMEOUT);
            tile_preview.set_opacity(0);
            tile_preview.restore_easing_state();
        }
    }

    private void tile_preview_transition_complete()
    {
        if (tile_preview.get_opacity() == 0x00) {
            this.tile_preview.hide();
        }
    }

    static int tab_sort(Meta.Window a, Meta.Window b)
    {
        uint32 at;
        uint32 bt;

        at = a.get_user_time();
        bt = a.get_user_time();

        if (at < bt) {
            return -1;
        }
        if (at > bt) {
            return 1;
        }
        return 0;
    }
    static int tab_sort_reverse(Meta.Window a, Meta.Window b)
    {
        uint32 at;
        uint32 bt;

        at = a.get_user_time();
        bt = a.get_user_time();

        if (at < bt) {
            return 1;
        }
        if (at > bt) {
            return -1;
        }
        return 0;
    }

    unowned Meta.Workspace? cur_workspace = null;
    List<weak Meta.Window>? cur_tabs = null;
    int cur_index = 0;
    uint32 last_time = -1;

    void invalidate_tab(Meta.Workspace space, Meta.Window window)
    {
        if (space == cur_workspace) {
            cur_tabs = null;
            cur_index = 0;
            last_time = -1;
        }
    }

    public static const uint32 MAX_TAB_ELAPSE = 2000;

    public void switch_windows_backward(Meta.Display display, Meta.Screen screen,
                     Meta.Window? window, Clutter.KeyEvent? event,
                     Meta.KeyBinding binding)
    {
        uint32 cur_time = display.get_current_time();

        var workspace = screen.get_active_workspace();

        string? data = null;
        if ((data = workspace.get_data("__flagged")) == null) {
            workspace.window_added.connect(invalidate_tab);
            workspace.window_removed.connect(invalidate_tab);
            workspace.set_data("__flagged", "yes");
        }

        if (workspace != cur_workspace || cur_time - last_time >= MAX_TAB_ELAPSE) {
            cur_workspace = workspace;
            cur_tabs = null;
            cur_index = 0;
        }
        last_time = cur_time;

        if (cur_tabs == null) {
            cur_tabs = display.get_tab_list(Meta.TabList.NORMAL, workspace);
            CompareFunc<weak Meta.Window> cm = Budgie.BudgieWM.tab_sort_reverse;
            cur_tabs.sort(cm);
        }
        if (cur_tabs == null) {
            return;
        }
        switch_switcher();
    }

    public void switch_windows(Meta.Display display, Meta.Screen screen,
                     Meta.Window? window, Clutter.KeyEvent? event,
                     Meta.KeyBinding binding)
    {
        uint32 cur_time = display.get_current_time();

        var workspace = screen.get_active_workspace();

        string? data = null;
        if ((data = workspace.get_data("__flagged")) == null) {
            workspace.window_added.connect(invalidate_tab);
            workspace.window_removed.connect(invalidate_tab);
            workspace.set_data("__flagged", "yes");
        }

        if (workspace != cur_workspace || cur_time - last_time >= MAX_TAB_ELAPSE) {
            cur_workspace = workspace;
            cur_tabs = null;
            cur_index = 0;
        }
        last_time = cur_time;

        if (cur_tabs == null) {
            cur_tabs = display.get_tab_list(Meta.TabList.NORMAL, workspace);
            CompareFunc<weak Meta.Window> cm = Budgie.BudgieWM.tab_sort;
            cur_tabs.sort(cm);
        }
        if (cur_tabs == null) {
            return;
        }
        switch_switcher();
    }

    public void switch_switcher()
    {
        /* Pass each window over to tabswitcher */
        foreach (var child in cur_tabs) {
            uint32 xid = (uint32)child.get_xwindow();
            switcher_proxy.PassItem(xid, child.get_user_time());
        }
        cur_index++;
        if (cur_index > cur_tabs.length()-1) {
            cur_index = 0;
        }
        /* Get the new selected window over to TabSwitcher */
        var win = cur_tabs.nth_data(cur_index);
        if (win == null) {
            return;
        }
        uint32 curr_xid = (uint32)win.get_xwindow();
        switcher_proxy.ShowSwitcher(curr_xid);
    }

    public void stop_switch_windows()
    {
        switcher_proxy.StopSwitcher();
    }


    /* EVEN MORE LEVELS OF DERP. */
    Clutter.Actor? out_group = null;
    Clutter.Actor? in_group = null;
    public override void kill_switch_workspace()
    {
        if (this.out_group != null) {
            out_group.transitions_completed();
        }
    }

    void switch_workspace_done()
    {
        var screen = this.get_screen();

        foreach (var actor in Meta.Compositor.get_window_actors(screen)) {
            Clutter.Actor? orig_parent = actor.get_data("orig-parent");

            if (orig_parent == null) {
                continue;
            }

            actor.ref();
            actor.get_parent().remove_child(actor);
            orig_parent.add_child(actor);
            actor.unref();

            actor.set_data("orig-parent", null);
        }

        SignalHandler.disconnect_by_func(out_group, (void*)switch_workspace_done, this);

        out_group.remove_all_transitions();
        in_group.remove_all_transitions();
        out_group.destroy();
        out_group = null;
        in_group.destroy();
        in_group = null;

        this.switch_workspace_completed();
    }


    public static const int SWITCH_TIMEOUT = 250;
    public override void switch_workspace(int from, int to, Meta.MotionDirection direction)
    {
        // Stop the Switcher if it was showing
        this.stop_switch_windows();

        int screen_width;
        int screen_height;

        if (from == to) {
            this.switch_workspace_completed();
            return;
        }

        out_group = new Clutter.Actor();
        in_group = new Clutter.Actor();

        var screen = this.get_screen();
        var stage = Meta.Compositor.get_stage_for_screen(screen);

        stage.add_child(in_group);
        stage.add_child(out_group);
        stage.set_child_above_sibling(in_group, null);

        screen.get_size(out screen_width, out screen_height);

        /* TODO: Windows should slide "under" the panel/dock
         * Move "in-between" workspaces, e.g. 1->3 shows 2 */


        foreach (var actor in Meta.Compositor.get_window_actors(screen)) {
            var window = actor.get_meta_window();

            if (!window.showing_on_its_workspace() || window.is_on_all_workspaces()) {
                continue;
            }

            var space = window.get_workspace();
            var win_space = space.index();

            if (win_space == to || win_space == from) {

                var orig_parent = actor.get_parent();
                unowned Clutter.Actor? new_parent = win_space == to ? in_group : out_group;
                actor.set_data("orig-parent", orig_parent);

                actor.ref();
                orig_parent.remove_child(actor);
                new_parent.add_child(actor);
                actor.unref();
            }
        }

        int y_dest = 0;
        int x_dest = 0;

        if (direction == Meta.MotionDirection.UP ||
            direction == Meta.MotionDirection.UP_LEFT ||
            direction == Meta.MotionDirection.UP_RIGHT) {
            y_dest = screen_height;
        } else if (direction == Meta.MotionDirection.DOWN ||
                    direction == Meta.MotionDirection.DOWN_LEFT ||
                    direction == Meta.MotionDirection.DOWN_RIGHT) {
            y_dest = -screen_height;
        }

        if (direction == Meta.MotionDirection.LEFT ||
            direction == Meta.MotionDirection.UP_LEFT ||
            direction == Meta.MotionDirection.DOWN_LEFT) {
            x_dest = screen_width;
        } else if (direction == Meta.MotionDirection.RIGHT ||
                    direction == Meta.MotionDirection.UP_RIGHT ||
                    direction == Meta.MotionDirection.DOWN_RIGHT) {
            x_dest = -screen_width;
        }

        in_group.set_position(-x_dest, -y_dest);
        in_group.save_easing_state();
        in_group.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
        in_group.set_easing_duration(SWITCH_TIMEOUT);
        in_group.set_position(0, 0);
        in_group.restore_easing_state();

        out_group.transitions_completed.connect(switch_workspace_done);;

        out_group.save_easing_state();
        out_group.set_easing_mode(Clutter.AnimationMode.EASE_OUT_QUAD);
        out_group.set_easing_duration(SWITCH_TIMEOUT);
        out_group.set_position(x_dest, y_dest);
        out_group.restore_easing_state();
    }
}

/**
 * Store/restore focused window for use of the popover manager in budgie.
 * This part of the equation is inspired by wingpanel, which uses our
 * popover manager.
 */
[DBus (name = "org.budgie_desktop.BudgieWM")]
public class BudgieWMDBUS : GLib.Object
{

    unowned Budgie.BudgieWM? wm;

    [DBus (visible = false)]
    public BudgieWMDBUS(Budgie.BudgieWM? wm)
    {
        this.wm = wm;
    }

    [DBus (visible = false)]
    void on_bus_acquired(DBusConnection conn)
    {
        try {
            conn.register_object("/org/budgie_desktop/BudgieWM", this);
        } catch (Error e) {
            message("Unable to register BudgieWMDBUS: %s", e.message);
        }
    }

    [DBus (visible = false)]
    public void serve()
    {
        Bus.own_name(BusType.SESSION, "org.budgie_desktop.BudgieWM",
            BusNameOwnerFlags.ALLOW_REPLACEMENT|BusNameOwnerFlags.REPLACE,
            on_bus_acquired, null, null);
    }

    public void store_focused()
    {
        this.wm.store_focused();
    }

    public void restore_focused()
    {
        this.wm.restore_focused();
    }

} /* End BudgieWMDBUS */

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
