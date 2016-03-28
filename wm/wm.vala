/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {


public static const string MUTTER_EDGE_TILING  = "edge-tiling";
public static const string MUTTER_MODAL_ATTACH = "attach-modal-dialogs";
public static const string MUTTER_BUTTON_LAYOUT = "button-layout";
public static const string WM_SCHEMA           = "com.solus-project.budgie-wm";

public static const bool CLUTTER_EVENT_PROPAGATE = false;
public static const bool CLUTTER_EVENT_STOP      = true;

public static const string RAVEN_DBUS_NAME        = "com.solus_project.budgie.Raven";
public static const string RAVEN_DBUS_OBJECT_PATH = "/com/solus_project/budgie/Raven";

public static const string PANEL_DBUS_NAME        = "com.solus_project.budgie.Panel";
public static const string PANEL_DBUS_OBJECT_PATH = "/com/solus_project/budgie/Panel";

public static const string LOGIND_DBUS_NAME        = "org.freedesktop.login1";
public static const string LOGIND_DBUS_OBJECT_PATH = "/org/freedesktop/login1";

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


[DBus (name="com.solus_project.budgie.Raven")]
public interface RavenRemote : Object
{
    public abstract async void Toggle() throws Error;
}

[DBus (name = "com.solus_project.budgie.Panel")]
public interface PanelRemote : Object
{

    public abstract async void ActivateAction(int flags) throws Error;
}

[DBus (name = "org.freedesktop.login1.Manager")]
public interface LoginDRemote : GLib.Object
{
    public signal void PrepareForSleep(bool suspending);
}

public class BudgieWM : Meta.Plugin
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
    LoginDRemote? logind_proxy = null;

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

        /* Keep an eye out for systemd stuffs */
        if (have_logind()) {
            get_logind();
        }

        Meta.KeyBinding.set_custom_handler("panel-main-menu", launch_menu);
        Meta.KeyBinding.set_custom_handler("panel-run-dialog", launch_rundialog);
        Meta.KeyBinding.set_custom_handler("switch-windows", switch_windows);
        Meta.KeyBinding.set_custom_handler("switch-applications", switch_windows);

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
            unowned string[] args = BudgieWM.old_args;
            if (Gtk.init_check(ref args)) {
                BudgieWM.gtk_available = true;
                message("Got GTK+ now");
            } else {
                message("Still no GTK+");
            }
        }

        if (BudgieWM.gtk_available) {
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
            var actor = new BudgieBackground(screen, i);
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
                actor.show();
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
                actor.opacity = 0U;
                actor.show();

                actor.save_easing_state();
                actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
                actor.set_easing_duration(MAP_TIMEOUT);

                actor.opacity = 255U;
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
                actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
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
        actor.set("pivot-point", PV_CENTER);
        actor.save_easing_state();
        actor.set_easing_mode(Clutter.AnimationMode.EASE_IN_SINE);
        actor.set_easing_duration(MINIMIZE_TIMEOUT);
        actor.transitions_completed.connect(minimize_done);

        actor.set("opacity", 0U, "x", (double)icon.x, "y", (double)icon.y, "scale-x", 0.0, "scale-y", 0.0);
        actor.restore_easing_state();
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
        if (!this.use_animations) {
            this.destroy_completed(actor);
            return;
        }

        Meta.Window? window = actor.get_meta_window();
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
            this.tile_preview.transitions_completed.connect(do_transitions_completed);

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

    private void do_transitions_completed()
    {
        if (tile_preview.get_opacity() == 0x00) {
            this.tile_preview.hide();
        }
    }

    /* SERIOUS LEVELS OF DERP FOLLOW: This is alt+Tab shite ported from old Budgie
     * MUST fix. */
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
        cur_index++;
        if (cur_index > cur_tabs.length()-1) {
            cur_index = 0;
        }
        var win = cur_tabs.nth_data(cur_index);
        if (win == null) {
            return;
        }
        win.activate(display.get_current_time());
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
