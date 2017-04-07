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

#include "plugin-private.h"

#include <meta/prefs.h>

/**
 * Current gsettings schema for budgie-wm
 */
#define WM_SCHEMA "com.solus-project.budgie-wm"

void budgie_meta_plugin_confirm_display_change(MetaPlugin *plugin)
{
        /* TODO: Ask via Zenity! */
        meta_plugin_complete_display_change(plugin, TRUE);
}

void budgie_meta_plugin_start(MetaPlugin *plugin)
{
        ClutterActor *stage = NULL;
        MetaScreen *screen = NULL;
        ClutterActor *screen_group = NULL;

        screen = meta_plugin_get_screen(plugin);
        screen_group = meta_get_window_group_for_screen(screen);
        stage = meta_get_stage_for_screen(screen);

        /* Set up our overrides */
        meta_prefs_override_preference_schema("edge-tiling", WM_SCHEMA);
        meta_prefs_override_preference_schema("attach-modal-dialogs", WM_SCHEMA);
        meta_prefs_override_preference_schema("button-layout", WM_SCHEMA);

        /* TODO:
         *  - Hook up background group
         *  - Hook up dbus
         *  - Hook up signals + backgrounds
         *  - Set up keybindings + ibus, etc
         */

        clutter_actor_show(screen_group);
        clutter_actor_show(stage);
}

void budgie_meta_plugin_kill_window_effects(MetaPlugin *plugin, MetaWindowActor *actor)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(plugin);

        static AnimationType effects[] = {
                ANIMATION_TYPE_MINIMIZE,
                ANIMATION_TYPE_UNMINIMIZE,
                ANIMATION_TYPE_MAP,
                ANIMATION_TYPE_DESTROY,
        };

        /* Remove all possible effects from the window */
        for (size_t i = 0; i < sizeof(effects) / sizeof(effects[0]); i++) {
                budgie_meta_plugin_pop_animation(self, actor, effects[i]);
        }
}

void budgie_meta_plugin_push_animation(BudgieMetaPlugin *self, MetaWindowActor *actor,
                                       AnimationType flag)
{
        guint win_state;

        /* At worst, this returns NULL, which is cast to 0, the initial state */
        win_state = GPOINTER_TO_UINT(g_hash_table_lookup(self->win_effects, actor));
        /* Don't allow double-setting the flag .. */
        if ((win_state & flag) == flag) {
                return;
        }
        win_state |= flag;
        g_hash_table_replace(self->win_effects, actor, GUINT_TO_POINTER(win_state));
}

void budgie_meta_plugin_pop_animation(BudgieMetaPlugin *self, MetaWindowActor *actor,
                                      AnimationType flag)
{
        void (*pop_func)(MetaPlugin *, MetaWindowActor *);
        gpointer v = NULL;
        guint win_state;

        /* No effect for this window, bail. */
        v = g_hash_table_lookup(self->win_effects, actor);
        if (!v) {
                return;
        }

        /* Find a better solution. */
        clutter_actor_remove_all_transitions(CLUTTER_ACTOR(actor));

        win_state = GPOINTER_TO_UINT(v);

        switch (flag) {
        case ANIMATION_TYPE_MINIMIZE:
                pop_func = meta_plugin_minimize_completed;
                break;
        case ANIMATION_TYPE_UNMINIMIZE:
                pop_func = meta_plugin_unminimize_completed;
                break;
        case ANIMATION_TYPE_MAP:
                pop_func = meta_plugin_map_completed;
                break;
        case ANIMATION_TYPE_DESTROY:
                pop_func = meta_plugin_destroy_completed;
                break;
        default:
                /* No flag, derp */
                g_assert_not_reached();
                return;
        }

        /* If this flag is set, remove it, and call the relevant pop function */
        if ((win_state & flag) == flag) {
                pop_func(META_PLUGIN(self), actor);
                win_state ^= flag;
        }

        /* If flags persist, store the new state and return */
        if (win_state != 0) {
                g_hash_table_replace(self->win_effects, actor, GUINT_TO_POINTER(win_state));
                return;
        }
        /* Remove it now, no effects persist */
        g_hash_table_remove(self->win_effects, actor);
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
