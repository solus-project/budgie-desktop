/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#pragma once

#include <gtk/gtk.h>

G_BEGIN_DECLS

typedef struct _BudgieNetworkPlugin BudgieNetworkPlugin;
typedef struct _BudgieNetworkPluginClass BudgieNetworkPluginClass;

#define BUDGIE_TYPE_NETWORK_PLUGIN budgie_network_plugin_get_type()
#define BUDGIE_NETWORK_PLUGIN(o)                                                                   \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_NETWORK_PLUGIN, BudgieNetworkPlugin))
#define BUDGIE_IS_NETWORK_PLUGIN(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_NETWORK_PLUGIN))
#define BUDGIE_NETWORK_PLUGIN_CLASS(o)                                                             \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_NETWORK_PLUGIN, BudgieNetworkPluginClass))
#define BUDGIE_IS_NETWORK_PLUGIN_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_NETWORK_PLUGIN))
#define BUDGIE_NETWORK_PLUGIN_GET_CLASS(o)                                                         \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_NETWORK_PLUGIN, BudgieNetworkPluginClass))

struct _BudgieNetworkPluginClass {
        GObjectClass parent_class;
};

struct _BudgieNetworkPlugin {
        GObject parent;
};

GType budgie_network_plugin_get_type(void);

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
