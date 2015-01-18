/*
 * minimize.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "impl.h"

/** Duration of minimize animation */
#define MINIMIZE_TIMEOUT   200

static ClutterPoint PV_CENTER = { 0.5f, 0.5f };
static ClutterPoint PV_NORM = { 0.0f, 0.0f };

#pragma GCC diagnostic ignored "-Wpedantic"

/**
 * notify mutter
 */
static void minimize_done(ClutterActor *actor, MetaPlugin *plugin)
{
        clutter_actor_remove_all_transitions(actor);
        g_signal_handlers_disconnect_by_func(actor, G_CALLBACK(minimize_done), plugin);
        g_object_set(actor, "pivot-point", &PV_NORM, "opacity", 255, "scale-x", 1.0, "scale-y", 1.0, NULL);
        clutter_actor_hide(actor);
        meta_plugin_minimize_completed(plugin, META_WINDOW_ACTOR(actor));
}

void minimize(MetaPlugin *plugin, MetaWindowActor *window_actor)
{
        ClutterActor *actor = CLUTTER_ACTOR(window_actor);
        MetaRectangle icon;

        clutter_actor_remove_all_transitions(actor);

        if (MWT(window_actor) != META_WINDOW_NORMAL) {
                meta_plugin_minimize_completed(plugin, window_actor);
                return;
        }

        if (!meta_window_get_icon_geometry(MGETWINDOW(window_actor), &icon)) {
                icon.x = 0;
                icon.y = 0;
        }

        /* Initialise animation */
        g_object_set(actor, "pivot-point", &PV_CENTER, NULL);
        clutter_actor_save_easing_state(actor);
        clutter_actor_set_easing_mode(actor, CLUTTER_EASE_IN_SINE);
        clutter_actor_set_easing_duration(actor, MINIMIZE_TIMEOUT);
        g_signal_connect(actor, "transitions-completed", G_CALLBACK(minimize_done), plugin);

        /* Now animate. */
        g_object_set(actor, "opacity", 0, "x", (double)icon.x, "y", (double)icon.y, "scale-x", 0.0, "scale-y", 0.0, NULL);
        clutter_actor_restore_easing_state(actor);
}
