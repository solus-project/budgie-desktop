/*
 * core.c - Core Plugin.
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "config.h"

#include <meta/meta-plugin.h>
#include <meta/window.h>
#include <meta/meta-background-group.h>
#include <meta/meta-background-actor.h>
#include <meta/prefs.h>
#include <meta/keybindings.h>
#include <meta/util.h>
#include <meta/meta-version.h>

#include "plugin.h"
#include "legacy.h"
#include "impl.h"
#include "background.h"


G_DEFINE_TYPE_WITH_PRIVATE(BudgieWM, budgie_wm, META_TYPE_PLUGIN)

static void budgie_wm_dispose(GObject *object);
static void budgie_wm_start(MetaPlugin *plugin);

/* Budgie specific callbacks */
static void budgie_launch_menu(MetaDisplay *display,
                                MetaScreen *screen,
                                MetaWindow *window,
                                ClutterKeyEvent *event,
                                MetaKeyBinding *binding,
                                gpointer user_data);

static void budgie_launch_rundialog(MetaDisplay *display,
                                     MetaScreen *screen,
                                     MetaWindow *window,
                                     ClutterKeyEvent *event,
                                     MetaKeyBinding *binding,
                                     gpointer user_data);

static const MetaPluginInfo *budgie_plugin_info(MetaPlugin *plugin);

static void budgie_wm_class_init(BudgieWMClass *klass)
{
        GObjectClass *g_object_class;
        MetaPluginClass *plugin_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_wm_dispose;
        
        plugin_class = META_PLUGIN_CLASS(klass);
        plugin_class->start            = budgie_wm_start;
        plugin_class->map              = map;
        plugin_class->minimize         = minimize;
        plugin_class->destroy          = destroy;
        plugin_class->plugin_info      = budgie_plugin_info;

        /* Existing legacy code from old default plugin */
        plugin_class->switch_workspace = switch_workspace;
        plugin_class->show_tile_preview = show_tile_preview;
        plugin_class->hide_tile_preview = hide_tile_preview;
        plugin_class->kill_window_effects   = kill_window_effects;
        plugin_class->kill_switch_workspace = kill_switch_workspace;
        plugin_class->confirm_display_change = confirm_display_change;
}

static void budgie_wm_init(BudgieWM *self)
{
        self->priv = budgie_wm_get_instance_private(self);
        
        self->priv->info.name        = "Budgie WM";
        self->priv->info.version     = PACKAGE_VERSION;
        self->priv->info.author      = "Ikey Doherty";
        self->priv->info.license     = "GPL2";
        self->priv->info.description = "Budgie WM Plugin for Mutter";

        /* Override schemas for edge-tiling and attachment of modal dialogs to parent */
        meta_prefs_override_preference_schema(MUTTER_EDGE_TILING, BUDGIE_WM_SCHEMA);
        meta_prefs_override_preference_schema(MUTTER_MODAL_ATTACH, BUDGIE_WM_SCHEMA);
}

static void budgie_wm_dispose(GObject *object)
{
        /* Any stray lists the tab module might have */
        tabs_clean();
        G_OBJECT_CLASS(budgie_wm_parent_class)->dispose(object);
}

static void budgie_wm_start(MetaPlugin *plugin)
{
        BudgieWM *self = BUDGIE_WM(plugin);
        MetaScreen *screen = meta_plugin_get_screen(plugin);

        /* Init background */
        self->priv->background_group = meta_background_group_new ();
        clutter_actor_insert_child_below (meta_get_window_group_for_screen (screen),
        self->priv->background_group, NULL);

        g_signal_connect (screen, "monitors-changed",
        G_CALLBACK (on_monitors_changed), plugin);
        on_monitors_changed (screen, plugin);

        /* Now we're in action. */
        clutter_actor_show (meta_get_stage_for_screen (screen));

        /* Set up our own keybinding overrides */
        meta_keybindings_set_custom_handler(BUDGIE_KEYBINDING_MAIN_MENU,
                budgie_launch_menu, NULL, NULL);
        meta_keybindings_set_custom_handler(BUDGIE_KEYBINDING_RUN_DIALOG,
                budgie_launch_rundialog, NULL, NULL);
        meta_keybindings_set_custom_handler("switch-windows",
                (MetaKeyHandlerFunc)switch_windows, self, NULL);
        meta_keybindings_set_custom_handler("switch-applications",
                (MetaKeyHandlerFunc)switch_windows, self, NULL);
}

/* Budgie specific callbacks */
static void budgie_launch_menu(MetaDisplay *display,
                                MetaScreen *screen,
                                MetaWindow *window,
                                ClutterKeyEvent *event,
                                MetaKeyBinding *binding,
                                gpointer user_data)
{
        /* Ask budgie-panel to open the menu */
        g_spawn_command_line_async("budgie-panel --menu", NULL);
}

static void budgie_launch_rundialog(MetaDisplay *display,
                                     MetaScreen *screen,
                                     MetaWindow *window,
                                     ClutterKeyEvent *event,
                                     MetaKeyBinding *binding,
                                     gpointer user_data)
{
        /* Run the budgie-run-dialog
        * TODO: Make this path customisable */
        g_spawn_command_line_async("budgie-run-dialog", NULL);
}

static const MetaPluginInfo *budgie_plugin_info(MetaPlugin *plugin)
{
        return &BUDGIE_WM(plugin)->priv->info;
}
