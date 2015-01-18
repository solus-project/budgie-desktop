/*
 * tabs.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "impl.h"
#include <meta/display.h>

#define MAX_TAB_ELAPSE 500

static MetaWorkspace *cur_workspace = NULL;
static GList *cur_tabs = NULL;
static guint cur_index = 0;
static guint32 last_time = -1;

static gint tab_sort(const MetaWindow *a, const MetaWindow *b)
{
        guint32 at, bt;
        at = meta_window_get_user_time((MetaWindow*)a);
        bt = meta_window_get_user_time((MetaWindow*)b);
        return (at < bt) ? -1 : (at > bt);
}

/* Refresh the current tab list. Ideally we need to refresh it when we're
 * "done" alt+tabbing, but we have no UI component yet.
 */
static void invalidate_tab(MetaWorkspace *space, MetaWindow *window, gpointer udata)
{
        if (space == cur_workspace) {
                if (cur_tabs) {
                        g_list_free(cur_tabs);
                }
                cur_tabs = NULL;
                cur_index = 0;
                last_time = -1;
        }
}

void tabs_clean()
{
        if (cur_tabs) {
                g_list_free(cur_tabs);
                cur_tabs = NULL;
        }
}

void switch_windows(MetaDisplay *display, MetaScreen     *screen,
                     MetaWindow *window, ClutterKeyEvent *event,
                     MetaKeyBinding *binding, MetaPlugin *plugin)
{
        MetaWorkspace *workspace = NULL;
        MetaWindow *win = NULL;
        guint32 cur_time = meta_display_get_current_time(display);

        if (window) {
                workspace = meta_window_get_workspace(window);
        }
        if (!workspace) {
                workspace = meta_screen_get_active_workspace(screen);
        }

        if (!g_object_get_data(G_OBJECT(workspace), "__flagged")) {
                g_signal_connect(workspace, "window-added", G_CALLBACK(invalidate_tab), NULL);
                g_signal_connect(workspace, "window-removed", G_CALLBACK(invalidate_tab), NULL);
                g_object_set_data(G_OBJECT(workspace), "__flagged", "Ya.");
        }

        if (workspace != cur_workspace || cur_time - last_time >= MAX_TAB_ELAPSE) {
                cur_workspace = workspace;
                if (cur_tabs) {
                        g_list_free(cur_tabs);
                        cur_tabs = NULL;
                        cur_index = 0;
                }
        }
        last_time = cur_time;

        if (!cur_tabs) {
                cur_tabs = meta_display_get_tab_list(display, META_TAB_LIST_NORMAL, workspace);
                cur_tabs = g_list_sort(cur_tabs, (GCompareFunc)tab_sort);
        }
        if (!cur_tabs) {
                return;
        }
        cur_index++;
        if (cur_index > g_list_length(cur_tabs)-1) {
                cur_index = 0;
        }
        win = g_list_nth_data(cur_tabs, cur_index);
        if (!win) {
                return;
        }

        meta_window_activate(win, meta_display_get_current_time(display));
}
