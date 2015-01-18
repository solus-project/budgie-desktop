/*
 * impl.h
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#pragma once

#include <meta/meta-plugin.h>
#include <meta/window.h>

/**
 * Wrappers for long-to-type pita accessors. Just need to switch, dude.
 */
#define MGETWINDOWTYPE(x) meta_window_get_window_type(x)
#define MGETWINDOW(x) meta_window_actor_get_meta_window(x)
#define MWT(x) MGETWINDOWTYPE(MGETWINDOW(x))

/** Included during transition period for functions still not in impl/ */
#include "legacy.h"

/** Map functionality */
void map(MetaPlugin *plugin, MetaWindowActor *actor);

/** Opposite of map, really. */
void destroy(MetaPlugin *plugin, MetaWindowActor *window_actor);

/** Minimize handler.. */
void minimize(MetaPlugin *plugin, MetaWindowActor *window_actor);

/** ALT+Tab switching */
void switch_windows(MetaDisplay *display, MetaScreen     *screen,
                     MetaWindow *window, ClutterKeyEvent *event,
                     MetaKeyBinding *binding, MetaPlugin *plugin);
/** Perform cleanup */
void tabs_clean(void);
