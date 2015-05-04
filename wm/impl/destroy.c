/*
 * destroy.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "impl.h"

/** Duration of destroy animation */
#define DESTROY_TIMEOUT    170

/** What size to scale them to */
#define DESTROY_SCALE      0.6

static ClutterPoint PV_CENTER = { 0.5f, 0.5f };

#pragma GCC diagnostic ignored "-Wpedantic"

/**
 * notify mutter
 */
static void destroy_done(ClutterActor *actor, MetaPlugin *plugin)
{
        clutter_actor_remove_all_transitions(actor);
        g_signal_handlers_disconnect_by_func(actor, G_CALLBACK(destroy_done), plugin);
        meta_plugin_destroy_completed(plugin, META_WINDOW_ACTOR(actor));
}

void destroy(MetaPlugin *plugin, MetaWindowActor *window_actor)
{
        ClutterActor *actor = CLUTTER_ACTOR(window_actor);

        clutter_actor_remove_all_transitions(actor);

        switch (MWT(window_actor)) {
                case META_WINDOW_NOTIFICATION:
                case META_WINDOW_NORMAL:
                case META_WINDOW_DIALOG:
                case META_WINDOW_MODAL_DIALOG:
                        /* Initialise animation */
                        g_object_set(actor, "pivot-point", &PV_CENTER, NULL);
                        clutter_actor_save_easing_state(actor);
                        clutter_actor_set_easing_mode(actor, CLUTTER_EASE_OUT_QUAD);
                        clutter_actor_set_easing_duration(actor, DESTROY_TIMEOUT);
                        g_signal_connect(actor, "transitions-completed", G_CALLBACK(destroy_done), plugin);

                        /* Now animate. */
                        g_object_set(actor, "scale-x", DESTROY_SCALE, "scale-y", DESTROY_SCALE, "opacity", 0, NULL);
                        clutter_actor_restore_easing_state(actor);
                        break;
                case META_WINDOW_MENU:
                        /* Initialise animation */
                        clutter_actor_save_easing_state(actor);
                        clutter_actor_set_easing_mode(actor, CLUTTER_EASE_OUT_QUAD);
                        clutter_actor_set_easing_duration(actor, DESTROY_TIMEOUT);
                        g_signal_connect(actor, "transitions-completed", G_CALLBACK(destroy_done), plugin);

                        /* Now animate. */
                        g_object_set(actor, "opacity", 0, NULL);
                        clutter_actor_restore_easing_state(actor);
                        break;
                default:
                        meta_plugin_destroy_completed(plugin, window_actor);
                        break;
        }
}
