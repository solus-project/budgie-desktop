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

#include "../plugin-private.h"

#define MENU_MAP_SCALE_X 0.98f
#define MENU_MAP_SCALE_Y 0.95f
#define MENU_MAP_TIMEOUT 120

#define NOTIFICATION_MAP_SCALE_X 0.5f
#define NOTIFICATION_MAP_SCALE_Y 0.5f

#define MAP_SCALE 0.8f
#define MAP_TIMEOUT 170

static ClutterPoint pv_center = {
        .x = 0.5f, .y = 0.5f,
};

static void map_done(ClutterActor *actor, gpointer v)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(v);

        __extension__ g_signal_handlers_disconnect_by_func((gpointer)actor,
                                                           (gpointer)map_done,
                                                           (gpointer)self);
        budgie_meta_plugin_pop_animation(self, META_WINDOW_ACTOR(actor), ANIMATION_TYPE_MAP);
}

void budgie_meta_plugin_map(MetaPlugin *plugin, MetaWindowActor *actor)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(plugin);
        MetaWindow *window = meta_window_actor_get_meta_window(actor);
        ClutterActor *cactor = CLUTTER_ACTOR(actor);

        if (!self->use_animations) {
                clutter_actor_show(cactor);
                meta_plugin_map_completed(plugin, actor);
                return;
        }

        /* Reset previous transitions in case we're in transit.. */
        clutter_actor_remove_all_transitions(cactor);

        switch (meta_window_get_window_type(window)) {
        case META_WINDOW_POPUP_MENU:
        case META_WINDOW_DROPDOWN_MENU:
        case META_WINDOW_MENU:
                /* Handle menu animations for map */
                g_object_set(cactor,
                             "opacity",
                             0U,
                             "scale-x",
                             MENU_MAP_SCALE_X,
                             "scale-y",
                             MENU_MAP_SCALE_Y,
                             "pivot-point",
                             &pv_center,
                             NULL);
                clutter_actor_show(cactor);

                /* Begin transitioning */
                clutter_actor_save_easing_state(cactor);
                clutter_actor_set_easing_mode(cactor, CLUTTER_EASE_OUT_CIRC);
                clutter_actor_set_easing_duration(cactor, MENU_MAP_TIMEOUT);
                g_object_set(cactor, "scale-x", 1.0, "scale-y", 1.0, "opacity", 255U, NULL);
                break;
        case META_WINDOW_NOTIFICATION:
                /* Handle notification popup */
                g_object_set(cactor,
                             "opacity",
                             0U,
                             "scale-x",
                             NOTIFICATION_MAP_SCALE_X,
                             "scale-y",
                             NOTIFICATION_MAP_SCALE_Y,
                             "pivot-point",
                             &pv_center,
                             NULL);
                clutter_actor_show(cactor);

                /* Transitions */
                clutter_actor_save_easing_state(cactor);
                clutter_actor_set_easing_mode(cactor, CLUTTER_EASE_OUT_QUART);
                clutter_actor_set_easing_duration(cactor, MAP_TIMEOUT);
                g_object_set(cactor, "scale-x", 1.0, "scale-y", 1.0, "opacity", 255U, NULL);
                break;
        case META_WINDOW_NORMAL:
        case META_WINDOW_DIALOG:
        case META_WINDOW_MODAL_DIALOG:
                /* Handle dialogs */
                g_object_set(cactor,
                             "opacity",
                             0U,
                             "scale-x",
                             MAP_SCALE,
                             "scale-y",
                             MAP_SCALE,
                             "pivot-point",
                             &pv_center,
                             NULL);
                clutter_actor_show(cactor);

                /* Transitions */
                clutter_actor_save_easing_state(cactor);
                clutter_actor_set_easing_mode(cactor, CLUTTER_EASE_OUT_CIRC);
                clutter_actor_set_easing_duration(cactor, MAP_TIMEOUT);
                g_object_set(cactor, "scale-x", 1.0, "scale-y", 1.0, "opacity", 255U, NULL);
                break;
        default:
                /* iunno boss */
                clutter_actor_show(cactor);
                meta_plugin_map_completed(plugin, actor);
                return;
        }

        g_signal_connect(cactor, "transitions-completed", G_CALLBACK(map_done), self);
        budgie_meta_plugin_push_animation(self, actor, ANIMATION_TYPE_MAP);
        clutter_actor_restore_easing_state(cactor);
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 8
 * tab-width: 8
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=8 tabstop=8 expandtab:
 * :indentSize=8:tabSize=8:noTabs=true:
 */
