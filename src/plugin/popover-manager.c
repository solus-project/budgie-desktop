/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include "popover-manager.h"

typedef BudgiePopoverManagerIface BudgiePopoverManagerInterface;

G_DEFINE_INTERFACE(BudgiePopoverManager, budgie_popover_manager, G_TYPE_OBJECT)

static void budgie_popover_manager_default_init(__attribute__((unused))
                                                BudgiePopoverManagerIface *iface)
{
}

/**
 * budgie_popover_manager_register_popover:
 * @widget: (nullable): Widget that the popover is associated with
 * @popover: (nullable): A #GtkPopover to associated with the @widget
 *
 * Register a popover with this popover manager
 */
void budgie_popover_manager_register_popover(BudgiePopoverManager *self, GtkWidget *widget,
                                             GtkPopover *popover)
{
        if (!self) {
                return;
        }
        BUDGIE_POPOVER_MANAGER_GET_IFACE(self)->register_popover(self, widget, popover);
}

/**
 * budgie_popover_manager_unregister_popover:
 * @widget: (nullable): Widget that the popover is associated with
 *
 * Unegister a popover with this popover manager
 */
void budgie_popover_manager_unregister_popover(BudgiePopoverManager *self, GtkWidget *widget)
{
        if (!self) {
                return;
        }
        BUDGIE_POPOVER_MANAGER_GET_IFACE(self)->unregister_popover(self, widget);
}

/**
 * budgie_popover_manager_show_popover:
 * @widget: (nullable): Widget that the popover is associated with
 *
 * Show a popover previously with this popover manager
 */
void budgie_popover_manager_show_popover(BudgiePopoverManager *self, GtkWidget *widget)
{
        if (!self) {
                return;
        }
        BUDGIE_POPOVER_MANAGER_GET_IFACE(self)->show_popover(self, widget);
}
