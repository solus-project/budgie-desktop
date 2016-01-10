/*
 * This file is part of budgie-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#pragma once

#include <glib-object.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

typedef struct _BudgiePopoverManager BudgiePopoverManager;
typedef struct _BudgiePopoverManagerIface BudgiePopoverManagerIface;

#define BUDGIE_TYPE_POPOVER_MANAGER budgie_popover_manager_get_type()
#define BUDGIE_POPOVER_MANAGER(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManager))
#define BUDGIE_IS_POPOVER_MANAGER(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_POPOVER_MANAGER))
#define BUDGIE_POPOVER_MANAGER_IFACE(o) (G_TYPE_CHECK_INTERFACE_CAST((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManagerIface))
#define BUDGIE_IS_POPOVER_MANAGER_IFACE(o) (G_TYPE_CHECK_INTERFACE_TYPE((o), BUDGIE_TYPE_POPOVER_MANAGER))
#define BUDGIE_POPOVER_MANAGER_GET_IFACE(o) (G_TYPE_INSTANCE_GET_INTERFACE((o), BUDGIE_TYPE_POPOVER_MANAGER, BudgiePopoverManagerIface))

/**
 * BudgiePopoverManagerIface
 */
struct _BudgiePopoverManagerIface {
        GTypeInterface parent_iface;

        void (*register_popover) (BudgiePopoverManager *manager, GtkWidget *widget, GtkPopover *popover);
        void (*unregister_popover) (BudgiePopoverManager *manager, GtkWidget *widget);
        void (*show_popover) (BudgiePopoverManager *manager, GtkWidget *widget);

        gpointer padding[4];
};

void budgie_popover_manager_register_popover(BudgiePopoverManager *manager, GtkWidget *widget, GtkPopover *popover);
void budgie_popover_manager_unregister_popover(BudgiePopoverManager *manager, GtkWidget *widget);
void budgie_popover_manager_show_popover(BudgiePopoverManager *manager, GtkWidget *widget);

GType budgie_popover_manager_get_type(void);

G_END_DECLS
