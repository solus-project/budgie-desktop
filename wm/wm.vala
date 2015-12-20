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
public static const string MUTTER_MODAL_ATTACH = "attach-modal-dialog";
public static const string WM_SCHEMA           = "com.solus-project.arc.wm";

public class ArcWM : Meta.Plugin
{
    static Meta.PluginInfo info;

    public bool use_animations { public set ; public get ; default = true; }

    public static bool gtk_available = true;

    static Clutter.Point PV_CENTER;
    static Clutter.Point PV_NORM;

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

    public ArcWM()
    {
        Meta.Prefs.override_preference_schema(MUTTER_EDGE_TILING, WM_SCHEMA);
        Meta.Prefs.override_preference_schema(MUTTER_MODAL_ATTACH, WM_SCHEMA);

        /* Follow GTK's policy on animations */
        if (gtk_available) {
            var settings = Gtk.Settings.get_default();
            settings.bind_property("gtk-enable-animations", this, "use-animations");
        } 
    }

    public override unowned Meta.PluginInfo? plugin_info() {
        return info;
    }

    public override void start()
    {
        var screen = this.get_screen();
        var screen_group = Meta.Compositor.get_window_group_for_screen(screen);
        var stage = Meta.Compositor.get_stage_for_screen(screen);

        /* TODO: Add backgrounds, monitor handling, etc. */

        screen_group.show();
        stage.show();
    }


    static const int MAP_TIMEOUT  = 170;
    static const float MAP_SCALE  = 0.8f;
    static const int FADE_TIMEOUT = 165;

    void map_done(Clutter.Actor? actor)
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
            case Meta.WindowType.NOTIFICATION:
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
