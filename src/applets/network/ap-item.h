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
#include <nm-access-point.h>

G_BEGIN_DECLS

typedef struct _BudgieAccessPointItem BudgieAccessPointItem;
typedef struct _BudgieAccessPointItemClass BudgieAccessPointItemClass;

#define BUDGIE_TYPE_ACCESS_POINT_ITEM budgie_access_point_item_get_type()
#define BUDGIE_ACCESS_POINT_ITEM(o)                                                                \
        (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_ACCESS_POINT_ITEM, BudgieAccessPointItem))
#define BUDGIE_IS_ACCESS_POINT_ITEM(o)                                                             \
        (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_ACCESS_POINT_ITEM))
#define BUDGIE_ACCESS_POINT_ITEM_CLASS(o)                                                          \
        (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_ACCESS_POINT_ITEM, BudgieAccessPointItemClass))
#define BUDGIE_IS_ACCESS_POINT_ITEM_CLASS(o)                                                       \
        (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_ACCESS_POINT_ITEM))
#define BUDGIE_ACCESS_POINT_ITEM_GET_CLASS(o)                                                      \
        (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_ACCESS_POINT_ITEM, BudgieAccessPointItemClass))

GType budgie_access_point_item_get_type(void);

/**
 * Public for the plugin to allow registration of types
 */
void budgie_access_point_item_init_gtype(GTypeModule *module);

/**
 * Construct a new BudgieAccessPointItem
 */
GtkWidget *budgie_access_point_item_new(NMAccessPoint *ap);

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
