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

void budgie_meta_plugin_show_window_menu(MetaPlugin *plugin, MetaWindow *window,
                                         MetaWindowMenuType menu, int x, int y)
{
        /* No-op currently */
}

/**
 * Virtually the same as show_window_menu
 */
void budgie_meta_plugin_show_window_menu_for_rect(MetaPlugin *plugin, MetaWindow *window,
                                                  MetaWindowMenuType menu, MetaRectangle *rect)
{
        budgie_meta_plugin_show_window_menu(plugin, window, menu, rect->x, rect->y);
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
