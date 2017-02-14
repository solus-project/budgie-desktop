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
        /* Can't do anything here until we have actor->transition mapping */
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
