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

#include <budgie-desktop/plugin.h>
#include <gtk/gtk.h>

#define __budgie_unused__ __attribute__((unused))

G_BEGIN_DECLS

typedef struct _BudgieNetworkApplet BudgieNetworkApplet;
typedef struct _BudgieNetworkAppletClass BudgieNetworkAppletClass;

#define BUDGIE_TYPE_NETWORK_APPLET budgie_network_applet_get_type()
#define BUDGIE_NETWORK_APPLET(o)                                                                   \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_NETWORK_APPLET, BudgieNetworkApplet))
#define BUDGIE_IS_NETWORK_APPLET(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_NETWORK_APPLET))
#define BUDGIE_NETWORK_APPLET_CLASS(o)                                                             \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_NETWORK_APPLET, BudgieNetworkAppletClass))
#define BUDGIE_IS_NETWORK_APPLET_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_NETWORK_APPLET))
#define BUDGIE_NETWORK_APPLET_GET_CLASS(o)                                                         \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_NETWORK_APPLET, BudgieNetworkAppletClass))

GType budgie_network_applet_get_type(void);

/**
 * Public for the plugin to allow registration of types
 */
void budgie_network_applet_init_gtype(GTypeModule *module);

/**
 * Construct a new BudgieNetworkApplet
 */
BudgieApplet *budgie_network_applet_new(void);

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
