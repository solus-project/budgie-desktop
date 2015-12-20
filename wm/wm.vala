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
        /* TODO: Add backgrounds, monitor handling, etc. */
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

    public override void destroy(Meta.WindowActor actor)
    {
        this.destroy_completed(actor);
    }

    public override void minimize(Meta.WindowActor actor)
    {
        this.minimize_completed(actor);
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
