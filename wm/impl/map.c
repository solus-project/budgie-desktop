/*
 * map.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "impl.h"

/* For mapping normal windows */
#define MAP_TIMEOUT     150

/* Initial scale (from 0.8 to 1.0) */
#define MAP_SCALE       0.8f

/* How long to fade in a menu */
#define FADE_TIMEOUT    115

/* To be used in some normal sense somewhere else.. */
static ClutterPoint PV_CENTER = { 0.5f, 0.5f };
static ClutterPoint PV_NORM = { 0.0f, 0.0f };

#pragma GCC diagnostic ignored "-Wpedantic"

/**
 * Simply restore pivot point and complete the effect within mutter
 */
static void map_done(ClutterActor *actor, MetaPlugin *plugin)
{
        clutter_actor_remove_all_transitions(actor);
        g_signal_handlers_disconnect_by_func(actor, G_CALLBACK(map_done), plugin);
        g_object_set(actor, "pivot-point", &PV_NORM, NULL);
        meta_plugin_map_completed(plugin, META_WINDOW_ACTOR(actor));
}

void map(MetaPlugin *plugin, MetaWindowActor *window_actor)
{
        ClutterActor *actor = CLUTTER_ACTOR(window_actor);

        clutter_actor_remove_all_transitions(actor);

        switch (MWT(window_actor)) {
                case META_WINDOW_POPUP_MENU:
                case META_WINDOW_DROPDOWN_MENU:
                case META_WINDOW_NOTIFICATION:
                        /* For menus we'll give em a nice fade in */
                        g_object_set(actor, "opacity", 0, NULL);
                        clutter_actor_show(actor);

                        clutter_actor_save_easing_state(actor);
                        clutter_actor_set_easing_mode(actor, CLUTTER_EASE_IN_SINE);
                        clutter_actor_set_easing_duration(actor, FADE_TIMEOUT);
                        g_signal_connect(actor, "transitions-completed", G_CALLBACK(map_done), plugin);

                        g_object_set(actor, "opacity", 255, NULL);
                        clutter_actor_restore_easing_state(actor);
                        break;
                case META_WINDOW_NORMAL:
                case META_WINDOW_DIALOG:
                case META_WINDOW_MODAL_DIALOG:
                        g_object_set(actor, "opacity", 0, "scale-x", MAP_SCALE, "scale-y", MAP_SCALE, "pivot-point", &PV_CENTER, NULL);
                        clutter_actor_show(actor);

                        /* Initialise animation */
                        clutter_actor_save_easing_state(actor);
                        clutter_actor_set_easing_mode(actor, CLUTTER_EASE_IN_SINE);
                        clutter_actor_set_easing_duration(actor, MAP_TIMEOUT);
                        g_signal_connect(actor, "transitions-completed", G_CALLBACK(map_done), plugin);

                        /* Now animate. */
                        g_object_set(actor, "scale-x", 1.0, "scale-y", 1.0, "opacity", 255, NULL);
                        clutter_actor_restore_easing_state(actor);
                        break;
                default:
                        meta_plugin_map_completed(plugin, window_actor);
                        break;
        }
}
