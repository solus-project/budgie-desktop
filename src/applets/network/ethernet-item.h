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
#include <nm-device.h>

G_BEGIN_DECLS

typedef struct _BudgieEthernetItem BudgieEthernetItem;
typedef struct _BudgieEthernetItemClass BudgieEthernetItemClass;

#define BUDGIE_TYPE_ETHERNET_ITEM budgie_ethernet_item_get_type()
#define BUDGIE_ETHERNET_ITEM(o)                                                                    \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_ETHERNET_ITEM, BudgieEthernetItem))
#define BUDGIE_IS_ETHERNET_ITEM(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_ETHERNET_ITEM))
#define BUDGIE_ETHERNET_ITEM_CLASS(o)                                                              \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_ETHERNET_ITEM, BudgieEthernetItemClass))
#define BUDGIE_IS_ETHERNET_ITEM_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_ETHERNET_ITEM))
#define BUDGIE_ETHERNET_ITEM_GET_CLASS(o)                                                          \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_ETHERNET_ITEM, BudgieEthernetItemClass))

GType budgie_ethernet_item_get_type(void);

/**
 * Public for the plugin to allow registration of types
 */
void budgie_ethernet_item_init_gtype(GTypeModule *module);

/**
 * Construct a new BudgieEthernetItem
 */
GtkWidget *budgie_ethernet_item_new(NMDevice *device, gint index);

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
