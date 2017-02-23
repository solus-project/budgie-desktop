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
#include "tile-widget.h"
#include "util.h"

static ClutterPoint pv_center = {
        .x = 0.5f, .y = 0.5f,
};

static void tile_preview_done(ClutterActor *actor, __budgie_unused__ gpointer v)
{
        guint8 opacity = clutter_actor_get_opacity(actor);
        if (opacity == 0x00) {
                clutter_actor_hide(actor);
        }
}

void budgie_meta_plugin_show_tile_preview(MetaPlugin *plugin, MetaWindow *window,
                                          MetaRectangle *tile_rect,
                                          __budgie_unused__ int tile_monitor_number)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(plugin);
        MetaScreen *screen = NULL;
        ClutterActor *screen_group = NULL;
        ClutterActor *tiler = self->tiler;
        ClutterActor *win_actor = NULL;
        gfloat x, y, width, height = 0.0f;

        screen = meta_plugin_get_screen(plugin);
        screen_group = meta_get_window_group_for_screen(screen);

        /* Create the tile preview on-demand */
        if (!self->tiler) {
                tiler = self->tiler = budgie_tile_preview_new();
                clutter_actor_add_child(screen_group, tiler);
                g_signal_connect(tiler,
                                 "transitions-completed",
                                 G_CALLBACK(tile_preview_done),
                                 NULL);
        }

        /* Skip same tile preview */
        if (clutter_actor_is_visible(tiler) &&
            meta_rectangle_equal(&(BUDGIE_TILE_PREVIEW(tiler)->rect), tile_rect)) {
                return;
        }

        win_actor = CLUTTER_ACTOR(meta_window_get_compositor_private(window));

        /* Prepare initial state.. */
        clutter_actor_remove_all_transitions(tiler);
        g_object_get(G_OBJECT(win_actor),
                     "x",
                     &x,
                     "y",
                     &y,
                     "width",
                     &width,
                     "height",
                     &height,
                     NULL);
        clutter_actor_set_position(tiler, x, y);
        clutter_actor_set_size(tiler, width, height);
        g_object_set(tiler, "scale-x", 0.5f, "scale-y", 0.5f, "pivot-point", &pv_center, NULL);

        clutter_actor_set_child_below_sibling(screen_group, tiler, win_actor);
        BUDGIE_TILE_PREVIEW(tiler)->rect = *tile_rect;
        clutter_actor_show(tiler);

        /* Start the animation up */
        clutter_actor_save_easing_state(tiler);
        clutter_actor_set_easing_mode(tiler, CLUTTER_EASE_OUT_QUAD);
        clutter_actor_set_easing_duration(tiler, 170);

        /* New coords */
        clutter_actor_set_position(tiler, (gfloat)tile_rect->x, (gfloat)tile_rect->y);
        clutter_actor_set_size(tiler, (gfloat)tile_rect->width, (gfloat)tile_rect->height);

        /* Fire it off */
        g_object_set(tiler, "scale-x", 1.0f, "scale-y", 1.0f, NULL);
        clutter_actor_restore_easing_state(tiler);
}

void budgie_meta_plugin_hide_tile_preview(MetaPlugin *plugin)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(plugin);
        ClutterActor *tiler = self->tiler;

        if (!self->tiler) {
                return;
        }
        clutter_actor_remove_all_transitions(tiler);
        clutter_actor_set_easing_mode(tiler, CLUTTER_EASE_OUT_QUAD);
        clutter_actor_set_easing_duration(tiler, 165);
        clutter_actor_set_opacity(tiler, 0);
        clutter_actor_restore_easing_state(tiler);
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
