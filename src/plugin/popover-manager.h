/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#pragma once

#include <glib-object.h>
#include <gtk/gtk.h>

#include "popover.h"

G_BEGIN_DECLS

typedef struct _BudgiePopoverManager BudgiePopoverManager;
typedef struct _BudgiePopoverManagerClass BudgiePopoverManagerClass;
typedef struct _BudgiePopoverManagerPrivate BudgiePopoverManagerPrivate;

struct _BudgiePopoverManagerClass {
	GObjectClass parent_class;
};

struct _BudgiePopoverManager {
	GObject parent;
	BudgiePopoverManagerPrivate* priv;
};

#define BUDGIE_TYPE_POPOVER_MANAGER budgie_popover_manager_get_type()
#define BUDGIE_POPOVER_MANAGER(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManager))
#define BUDGIE_IS_POPOVER_MANAGER(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_POPOVER_MANAGER))
#define BUDGIE_POPOVER_MANAGER_CLASS(o) (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManagerClass))
#define BUDGIE_IS_POPOVER_MANAGER_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_POPOVER_MANAGER))
#define BUDGIE_POPOVER_MANAGER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManagerClass))

BudgiePopoverManager* budgie_popover_manager_new(void);

GType budgie_popover_manager_get_type(void);

/*
 * API Methods follow
 */
void budgie_popover_manager_register_popover(BudgiePopoverManager* manager, GtkWidget* parent_widget, BudgiePopover* popover);
void budgie_popover_manager_unregister_popover(BudgiePopoverManager* manager, GtkWidget* parent_widget);
void budgie_popover_manager_show_popover(BudgiePopoverManager* manager, GtkWidget* parent_widget);

G_END_DECLS
