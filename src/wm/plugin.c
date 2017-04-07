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

enum { PROP_USE_ANIMATIONS = 1, N_PROPS };

static GParamSpec *obj_properties[N_PROPS] = {
        NULL,
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
 * Set GObject properties
 */
static void budgie_meta_plugin_set_property(GObject *object, guint id, const GValue *value,
                                            GParamSpec *spec)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(object);

        switch (id) {
        case PROP_USE_ANIMATIONS:
                self->use_animations = g_value_get_boolean(value);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

/**
 * Get GObject properties
 */
static void budgie_meta_plugin_get_property(GObject *object, guint id, GValue *value,
                                            GParamSpec *spec)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(object);

        switch (id) {
        case PROP_USE_ANIMATIONS:
                g_value_set_boolean(value, self->use_animations);
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

/**
 * budgie_meta_plugin_dispose:
 *
 * Clean up a BudgieMetaPlugin instance
 */
static void budgie_meta_plugin_dispose(GObject *obj)
{
        BudgieMetaPlugin *self = BUDGIE_META_PLUGIN(obj);

        g_clear_pointer(&self->win_effects, g_hash_table_unref);

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
        obj_class->set_property = budgie_meta_plugin_set_property;
        obj_class->get_property = budgie_meta_plugin_get_property;

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
        // plug_class->kill_window_effects = budgie_meta_plugin_kill_window_effects;
        plug_class->kill_switch_workspace = budgie_meta_plugin_kill_switch_workspace;
        plug_class->confirm_display_change = budgie_meta_plugin_confirm_display_change;

        /* Hook up animations property */
        obj_properties[PROP_USE_ANIMATIONS] =
            g_param_spec_boolean("use-animations",
                                 "Use Animations",
                                 "Whether or not we can use animations for effects",
                                 TRUE,
                                 G_PARAM_READWRITE);

        g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

/**
 * budgie_meta_plugin_init:
 *
 * Handle construction of the BudgieMetaPlugin
 */
static void budgie_meta_plugin_init(__budgie_unused__ BudgieMetaPlugin *self)
{
        GHashTable *effects = NULL;

        /* Map a MetaWindowActor to an enum state, always != 0 (NULL) */
        effects = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, NULL);
        self->win_effects = effects;
        self->use_animations = TRUE;
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
