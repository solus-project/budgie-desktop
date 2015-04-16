/*
 * workspace.c
 * 
 * Copyright 2015 Jente Hidskes <hjdskes@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "impl.h"
#include "plugin.h"

/** Duration of switch animation */
#define SWITCH_TIMEOUT 250

void kill_switch_workspace(MetaPlugin *plugin)
{
        BudgieWMPrivate *priv = BUDGIE_WM(plugin)->priv;

        if (priv->out_group) {
                g_signal_emit_by_name(priv->out_group,
                                      "transitions-completed",
                                      priv->out_group,
                                      plugin,
                                      NULL);
        }
}

static void switch_workspace_done(ClutterActor *actor, gpointer user_data)
{
        BudgieWMPrivate *priv = BUDGIE_WM(user_data)->priv;
        MetaScreen *screen = meta_plugin_get_screen(META_PLUGIN(user_data));
        GList *l = meta_get_window_actors(screen);

        while (l) {
                ClutterActor *orig_parent = g_object_get_data(G_OBJECT(l->data), "orig-parent");

                if (orig_parent) {
                        ClutterActor *actor = CLUTTER_ACTOR(l->data);

                        g_object_ref(actor);
                        clutter_actor_remove_child(clutter_actor_get_parent(actor), actor);
                        clutter_actor_add_child(orig_parent, actor);
                        g_object_unref(actor);

                        g_object_set_data(G_OBJECT(actor), "orig-parent", NULL);
                }

                l = l->next;
        }

        g_signal_handlers_disconnect_by_func(priv->out_group,
                                             switch_workspace_done, user_data);
        clutter_actor_remove_all_transitions(priv->out_group);
        clutter_actor_remove_all_transitions(priv->in_group);
        clutter_actor_destroy(priv->out_group);
        clutter_actor_destroy(priv->in_group);
        priv->out_group = NULL;
        priv->in_group = NULL;
        meta_plugin_switch_workspace_completed(META_PLUGIN(user_data));
}

void switch_workspace(MetaPlugin *plugin, gint from, gint to,
                      MetaMotionDirection direction)
{
        BudgieWMPrivate *priv = BUDGIE_WM (plugin)->priv;
        MetaScreen *screen;
        GList *l;
        ClutterActor *stage;
        int screen_width, screen_height;
        int x_dest = 0, y_dest = 0;

        if (from == to) {
                meta_plugin_switch_workspace_completed(plugin);
                return;
        }

        priv->out_group = clutter_actor_new();
        priv->in_group = clutter_actor_new();
        screen = meta_plugin_get_screen(plugin);
        stage = meta_get_stage_for_screen(screen);
        clutter_actor_add_child(stage, priv->in_group);
        clutter_actor_add_child(stage, priv->out_group);
        clutter_actor_set_child_above_sibling(stage, priv->in_group, NULL);
        meta_screen_get_size(screen, &screen_width, &screen_height);

        // TODO: windows should slide "under" the panel/dock
        // TODO: move over "in-between" workspaces, e.g. 1->3 shows 2
        l = meta_get_window_actors(screen);
        while (l) {
                MetaWindow *window = meta_window_actor_get_meta_window(l->data);
                ClutterActor *actor = CLUTTER_ACTOR(l->data);
                MetaWorkspace *space;
                gint win_space;

                if (!meta_window_showing_on_its_workspace(window) ||
                    meta_window_is_on_all_workspaces(window)) {
                        l = l->next;
                        continue;
                }

                space = meta_window_get_workspace(window);
                win_space = meta_workspace_index(space);
                if (win_space == to || win_space == from) {
                        ClutterActor *orig_parent = clutter_actor_get_parent(actor);
                        ClutterActor *new_parent = win_space == to ? priv->in_group : priv->out_group;

                        g_object_set_data(G_OBJECT(actor),
                                          "orig-parent", orig_parent);

                        g_object_ref(actor);
                        clutter_actor_remove_child(orig_parent, actor);
                        clutter_actor_add_child(new_parent, actor);
                        g_object_unref(actor);
                }

                l = l->next;
        }

        if (direction == META_MOTION_UP ||
            direction == META_MOTION_UP_LEFT ||
            direction == META_MOTION_UP_RIGHT) {
                y_dest = screen_height;
        } else if (direction == META_MOTION_DOWN ||
                   direction == META_MOTION_DOWN_LEFT ||
                   direction == META_MOTION_DOWN_RIGHT) {
                y_dest = -screen_height;
        }

        if (direction == META_MOTION_LEFT ||
            direction == META_MOTION_UP_LEFT ||
            direction == META_MOTION_DOWN_LEFT) {
                x_dest = screen_width;
        } else if (direction == META_MOTION_RIGHT ||
                   direction == META_MOTION_UP_RIGHT ||
                   direction == META_MOTION_DOWN_RIGHT) {
                x_dest = -screen_width;
        }

        /* Animate-in the new workspace. */
        clutter_actor_set_position(priv->in_group, -x_dest, -y_dest);
        clutter_actor_save_easing_state(priv->in_group);
        clutter_actor_set_easing_mode(priv->in_group, CLUTTER_EASE_OUT_QUAD);
        clutter_actor_set_easing_duration(priv->in_group, SWITCH_TIMEOUT);
        clutter_actor_set_position(priv->in_group, 0, 0);
        clutter_actor_restore_easing_state(priv->in_group);

        /* Animate-out the previous workspace. */
        g_signal_connect(priv->out_group, "transitions-completed",
                         G_CALLBACK(switch_workspace_done), plugin);
        clutter_actor_save_easing_state(priv->out_group);
        clutter_actor_set_easing_mode(priv->out_group, CLUTTER_EASE_OUT_QUAD);
        clutter_actor_set_easing_duration(priv->out_group, SWITCH_TIMEOUT);
        clutter_actor_set_position(priv->out_group, x_dest, y_dest);
        clutter_actor_restore_easing_state(priv->out_group);
}

