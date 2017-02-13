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
        /* Main startup sequence here.
         * TODO: Show the stage
         */
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
