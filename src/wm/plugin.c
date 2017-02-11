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

#include "plugin.h"

struct _BudgieMetaPluginClass {
        MetaPluginClass parent_class;
};

struct _BudgieMetaPlugin {
        MetaPlugin parent;
};

G_DEFINE_TYPE(BudgieMetaPlugin, budgie_meta_plugin, META_TYPE_PLUGIN)

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

        obj_class->dispose = budgie_meta_plugin_dispose;
}

/**
 * budgie_meta_plugin_init:
 *
 * Handle construction of the BudgieMetaPlugin
 */
static void budgie_meta_plugin_init(BudgieMetaPlugin *self)
{
        /* TODO: Any form of init */
}

void budgie_meta_plugin_register_type(void)
{
        meta_plugin_manager_set_plugin_type(budgie_meta_plugin_get_type());
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
