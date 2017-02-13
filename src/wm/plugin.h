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

G_BEGIN_DECLS

typedef struct _BudgieMetaPlugin BudgieMetaPlugin;
typedef struct _BudgieMetaPluginClass BudgieMetaPluginClass;

#define BUDGIE_TYPE_META_PLUGIN budgie_meta_plugin_get_type()
#define BUDGIE_META_PLUGIN(o)                                                                      \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_META_PLUGIN, BudgieMetaPlugin))
#define BUDGIE_IS_META_PLUGIN(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_META_PLUGIN))
#define BUDGIE_META_PLUGIN_CLASS(o)                                                                \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_META_PLUGIN, BudgieMetaPluginClass))
#define BUDGIE_IS_META_PLUGIN_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_META_PLUGIN))
#define BUDGIE_META_PLUGIN_GET_CLASS(o)                                                            \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_META_PLUGIN, BudgieMetaPluginClass))

GType budgie_meta_plugin_get_type(void);

/**
 * Fixes an issue whereby mutter plugin symbols redefine themselves..
 */
void budgie_meta_plugin_register_type(void);

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
