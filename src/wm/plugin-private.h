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

#pragma once

#include <glib-object.h>
#include <meta/meta-plugin.h>

G_BEGIN_DECLS

/**
 * Begin managing the display
 */
void budgie_meta_plugin_start(MetaPlugin *plugin);

/**
 * Minimize requested for the window
 */
void budgie_meta_plugin_minimize(MetaPlugin *plugin, MetaWindowActor *actor);

/**
 * Unminimize (restore) requested for the window
 */
void budgie_meta_plugin_unminimize(MetaPlugin *plugin, MetaWindowActor *actor);

/**
 * Window is going to be made visible
 */
void budgie_meta_plugin_map(MetaPlugin *plugin, MetaWindowActor *actor);

/**
 * Window is being destroyed
 */
void budgie_meta_plugin_destroy(MetaPlugin *plugin, MetaWindowActor *actor);

/**
 * Switch from the specified workspace to the new workspace, respecting
 * the given directional hint.
 */
void budgie_meta_plugin_switch_workspace(MetaPlugin *plugin, gint from, gint to,
                                         MetaMotionDirection direction);

/**
 * Show a tiling indicator in the given region to indicate availability
 * of a tiling operation for the associated window being tiled.
 */
void budgie_meta_plugin_show_tile_preview(MetaPlugin *plugin, MetaWindow *window,
                                          MetaRectangle *tile_Rect, int tile_monitor_number);

/**
 * Hide tile preview from the display
 */
void budgie_meta_plugin_hide_tile_preview(MetaPlugin *plugin);

/**
 * Show the window's associated menu at the given location
 */
void budgie_meta_plugin_show_window_menu(MetaPlugin *plugin, MetaWindow *window,
                                         MetaWindowMenuType menu, int x, int y);

/**
 * Virtually the same as show_window_menu
 */
void budgie_meta_plugin_show_window_menu_for_rect(MetaPlugin *plugin, MetaWindow *window,
                                                  MetaWindowMenuType menu, MetaRectangle *rect);

/**
 * The compositor requested we kill the effects on this window as it needs destroying
 */
void budgie_meta_plugin_kill_window_effects(MetaPlugin *plugin, MetaWindowActor *actor);

/**
 * Immediately terminate any animations/effects in transit for a workspace switch
 */
void budgie_meta_plugin_kill_switch_workspace(MetaPlugin *plugin);

/**
 * Ask the user if they're ok with the display change, and give them a
 * timeout in which to revert to the old display mode.
 */
void budgie_meta_plugin_confirm_display_change(MetaPlugin *plugin);

G_END_DECLS

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
