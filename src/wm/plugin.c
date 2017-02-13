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

#define _GNU_SOURCE

#include <meta/meta-plugin.h>

#include "config.h"
#include "plugin-private.h"
#include "plugin.h"
#include "util.h"

struct _BudgieMetaPluginClass {
        MetaPluginClass parent_class;
};

/**
 * Actual instance definition
 */
struct _BudgieMetaPlugin {
        MetaPlugin parent;
};

/**
 * Make ourselves known to gobject
 */
G_DEFINE_TYPE(BudgieMetaPlugin, budgie_meta_plugin, META_TYPE_PLUGIN)

/**
 * Forward-declare
 */
static const MetaPluginInfo *budgie_meta_plugin_info(MetaPlugin *plugin);

/**
 * How we identify ourselves to Mutter
 */
static const MetaPluginInfo budgie_plugin_info = {.name = "Budgie WM",
                                                  .version = PACKAGE_VERSION,
                                                  .author = "Ikey Doherty",
                                                  .license = "GPL-2.0",
                                                  .description = "Budgie Window Manager" };

/**
 * budgie_meta_plugin_dispose:
 *
 * Clean up a BudgieMetaPlugin instance
 */
static void budgie_meta_plugin_dispose(GObject *obj)
{
        G_OBJECT_CLASS(budgie_meta_plugin_parent_class)->dispose(obj);
}

/**
 * budgie_meta_plugin_class_init:
 *
 * Handle class initialisation
 */
static void budgie_meta_plugin_class_init(BudgieMetaPluginClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);
        MetaPluginClass *plug_class = META_PLUGIN_CLASS(klazz);

        /* gobject vtable */
        obj_class->dispose = budgie_meta_plugin_dispose;

        /* Hook up the vtable
         * Note: We're still going to need to add some more yet and handle
         * more than the old budgie-wm
         */
        plug_class->plugin_info = budgie_meta_plugin_info;
        plug_class->start = budgie_meta_plugin_start;
        plug_class->minimize = budgie_meta_plugin_minimize;
        plug_class->unminimize = budgie_meta_plugin_unminimize;
        plug_class->map = budgie_meta_plugin_map;
        plug_class->destroy = budgie_meta_plugin_destroy;
        plug_class->switch_workspace = budgie_meta_plugin_switch_workspace;
        plug_class->show_tile_preview = budgie_meta_plugin_show_tile_preview;
        plug_class->hide_tile_preview = budgie_meta_plugin_hide_tile_preview;
        plug_class->show_window_menu = budgie_meta_plugin_show_window_menu;
        plug_class->show_window_menu_for_rect = budgie_meta_plugin_show_window_menu_for_rect;
        plug_class->kill_window_effects = budgie_meta_plugin_kill_window_effects;
        plug_class->kill_switch_workspace = budgie_meta_plugin_kill_switch_workspace;
        plug_class->confirm_display_change = budgie_meta_plugin_confirm_display_change;
}

/**
 * budgie_meta_plugin_init:
 *
 * Handle construction of the BudgieMetaPlugin
 */
static void budgie_meta_plugin_init(__budgie_unused__ BudgieMetaPlugin *self)
{
        /* TODO: Any form of init */
}

void budgie_meta_plugin_register_type(void)
{
        meta_plugin_manager_set_plugin_type(budgie_meta_plugin_get_type());
}

/**
 * mutter API methods
 */

/**
 * Return the identifier for this budgie-wm plugin
 */
static const MetaPluginInfo *budgie_meta_plugin_info(__budgie_unused__ MetaPlugin *plugin)
{
        return &budgie_plugin_info;
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
