/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#define _GNU_SOURCE

#include "util.h"

BUDGIE_BEGIN_PEDANTIC
#include "popover-manager.h"
#include <gtk/gtk.h>
BUDGIE_END_PEDANTIC

struct _BudgiePopoverManagerClass {
        GObjectClass parent_class;
};

struct _BudgiePopoverManager {
        GObject parent;
        GHashTable *popovers;
        BudgiePopover *active_popover;
};

G_DEFINE_TYPE(BudgiePopoverManager, budgie_popover_manager, G_TYPE_OBJECT)

static gboolean budgie_popover_manager_enter_notify(BudgiePopoverManager *manager,
                                                    GdkEventCrossing *crossing, GtkWidget *widget);
static void budgie_popover_manager_link_signals(BudgiePopoverManager *manager,
                                                GtkWidget *parent_widget, BudgiePopover *popover);
static void budgie_popover_manager_unlink_signals(BudgiePopoverManager *manager,
                                                  GtkWidget *parent_widget, BudgiePopover *popover);
static gboolean budgie_popover_manager_coords_within_window(GtkWindow *window, gint root_x,
                                                            gint root_y);
static BudgiePopover *budgie_popover_manager_get_popover_for_coords(BudgiePopoverManager *self,
                                                                    gint root_x, gint root_y);
static gboolean budgie_popover_manager_popover_mapped(BudgiePopover *popover, GdkEvent *event,
                                                      BudgiePopoverManager *self);
static gboolean budgie_popover_manager_popover_unmapped(BudgiePopover *popover, GdkEvent *event,
                                                        BudgiePopoverManager *self);

/**
 * budgie_popover_manager_new:
 *
 * Construct a new BudgiePopoverManager object
 */
BudgiePopoverManager *budgie_popover_manager_new()
{
        return g_object_new(BUDGIE_TYPE_POPOVER_MANAGER, NULL);
}

/**
 * budgie_popover_manager_dispose:
 *
 * Clean up a BudgiePopoverManager instance
 */
static void budgie_popover_manager_dispose(GObject *obj)
{
        BudgiePopoverManager *self = NULL;

        self = BUDGIE_POPOVER_MANAGER(obj);
        g_clear_pointer(&self->popovers, g_hash_table_unref);

        G_OBJECT_CLASS(budgie_popover_manager_parent_class)->dispose(obj);
}

/**
 * budgie_popover_manager_class_init:
 *
 * Handle class initialisation
 */
static void budgie_popover_manager_class_init(BudgiePopoverManagerClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable hookup */
        obj_class->dispose = budgie_popover_manager_dispose;
}

/**
 * budgie_popover_manager_init:
 *
 * Handle construction of the BudgiePopoverManager
 */
static void budgie_popover_manager_init(BudgiePopoverManager *self)
{
        /* We don't re-ref anything as we just effectively hold floating references
         * to the WhateverTheyAres
         */
        self->popovers = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, NULL);
}

/**
 * budgie_popover_manager_register_popover:
 * @parent_widget: The widget that "owns" the popover (relative-to)
 * @popover: The popover that will be shown when the @parent_widget is activated
 *
 * Register a new popover with it's relative-to widget within the popover management
 * system. This will allow the popover to be activated when it's parent widget has
 * been activated by a mouse roll over, when another widget is visible.
 *
 * This allows the panel to provide a "menubar" like functionality for interaction
 * with multiple popovers in a natural fashion.
 */
void budgie_popover_manager_register_popover(BudgiePopoverManager *self, GtkWidget *parent_widget,
                                             BudgiePopover *popover)
{
        g_assert(self != NULL);
        g_return_if_fail(parent_widget != NULL && popover != NULL);

        if (g_hash_table_contains(self->popovers, parent_widget)) {
                g_warning("register_popover(): Widget %p is already registered",
                          (gpointer)parent_widget);
                return;
        }

        /* We're a popover manager, so we're meant for use in some kind of panel
         * situation. Use toplevel hints for better positioning */
        budgie_popover_set_position_policy(popover, BUDGIE_POPOVER_POSITION_TOPLEVEL_HINT);

        /* Stick it into the map and hook it up */
        budgie_popover_manager_link_signals(self, parent_widget, popover);
        g_hash_table_insert(self->popovers, parent_widget, popover);
}

/**
 * budgie_popover_manager_unregister_popover:
 * @parent_widget: The associated widget (key) for the registered popover
 *
 * Unregister a popover so that it is no longer managed by this implementation,
 * and is free to manage itself.
 */
void budgie_popover_manager_unregister_popover(BudgiePopoverManager *self, GtkWidget *parent_widget)
{
        g_assert(self != NULL);
        g_return_if_fail(parent_widget != NULL);
        BudgiePopover *popover = NULL;

        popover = g_hash_table_lookup(self->popovers, parent_widget);
        if (!popover) {
                g_warning("unregister_popover(): Widget %p is unknown", (gpointer)parent_widget);
                return;
        }

        budgie_popover_manager_unlink_signals(self, parent_widget, popover);
        g_hash_table_remove(self->popovers, parent_widget);
}

/**
 * show_one_popover:
 *
 * Show a popover on the idle loop to prevent any weird event locks
 */
static gboolean show_one_popover(gpointer v)
{
        gtk_widget_show(GTK_WIDGET(v));
        return FALSE;
}

/**
 * budgie_popover_manager_show_popover:
 * @parent_widget: The widget owning the popover to be shown
 *
 * Show a #BudgiePopover on screen belonging to the specified @parent_widget
 */
void budgie_popover_manager_show_popover(BudgiePopoverManager *self, GtkWidget *parent_widget)
{
        BudgiePopover *popover = NULL;

        g_assert(self != NULL);
        g_return_if_fail(parent_widget != NULL);

        popover = g_hash_table_lookup(self->popovers, parent_widget);
        if (!popover) {
                g_warning("show_popover(): Widget %p is unknown", (gpointer)parent_widget);
                return;
        }

        g_idle_add(show_one_popover, popover);
}

/**
 * budgie_popover_manager_widget_died:
 *
 * The widget has died, so remove it from our internal state
 */
static void budgie_popover_manager_widget_died(BudgiePopoverManager *self, GtkWidget *child)
{
        if (!g_hash_table_contains(self->popovers, child)) {
                return;
        }
        g_hash_table_remove(self->popovers, child);
}

/**
 * budgie_popover_manager_link_signals:
 *
 * Hook up the various signals we need to manage this popover correctly
 */
static void budgie_popover_manager_link_signals(BudgiePopoverManager *self,
                                                GtkWidget *parent_widget, BudgiePopover *popover)
{
        /* Need enter-notify to check if we entered a parent widget */
        g_signal_connect_swapped(popover,
                                 "enter-notify-event",
                                 G_CALLBACK(budgie_popover_manager_enter_notify),
                                 self);
        g_signal_connect_swapped(parent_widget,
                                 "destroy",
                                 G_CALLBACK(budgie_popover_manager_widget_died),
                                 self);
        g_signal_connect(popover,
                         "map-event",
                         G_CALLBACK(budgie_popover_manager_popover_mapped),
                         self);
        g_signal_connect(popover,
                         "unmap-event",
                         G_CALLBACK(budgie_popover_manager_popover_unmapped),
                         self);
}

/**
 * budgie_popover_manager_unlink_signals:
 *
 * Disconnect any prior signals for this popover so we stop receiving events for it
 */
static void budgie_popover_manager_unlink_signals(BudgiePopoverManager *self,
                                                  GtkWidget *parent_widget, BudgiePopover *popover)
{
        g_signal_handlers_disconnect_by_data(parent_widget, self);
        g_signal_handlers_disconnect_by_data(popover, self);
}

/**
 * budgie_popover_manager_enter_notify:
 *
 * Handle an enter-notify for a widget to handle roll-over selection when grabbed
 */
static gboolean budgie_popover_manager_enter_notify(BudgiePopoverManager *self,
                                                    GdkEventCrossing *crossing, GtkWidget *widget)
{
        BudgiePopover *target_popover = NULL;

        /* We only want to hear about the grabbed events */
        if (!GTK_IS_WINDOW(widget)) {
                return GDK_EVENT_PROPAGATE;
        }

        /* If we're inside the popover, not interested. */
        if (budgie_popover_manager_coords_within_window(GTK_WINDOW(widget),
                                                        (gint)crossing->x_root,
                                                        (gint)crossing->y_root)) {
                return GDK_EVENT_PROPAGATE;
        }

        target_popover = budgie_popover_manager_get_popover_for_coords(self,
                                                                       (gint)crossing->x_root,
                                                                       (gint)crossing->y_root);
        if (!target_popover) {
                return GDK_EVENT_PROPAGATE;
        }

        /* Don't show the same popover again. :P */
        if (target_popover == self->active_popover) {
                return GDK_EVENT_PROPAGATE;
        }

        if (self->active_popover) {
                gtk_widget_hide(GTK_WIDGET(self->active_popover));
                self->active_popover = NULL;
        }

        g_idle_add(show_one_popover, target_popover);

        return GDK_EVENT_STOP;
}

/**
 * budgie_popover_manager_coords_within_window:
 *
 * Window specific method that determines if X,Y is currently within the
 * confines of the GtkWindow. This helps us quickly determine that we've
 * re-entered a BudgiePopover and don't need to find an associated window.
 */
static gboolean budgie_popover_manager_coords_within_window(GtkWindow *window, gint root_x,
                                                            gint root_y)
{
        gint x, y = 0;
        gint w, h = 0;
        gtk_window_get_position(window, &x, &y);
        gtk_window_get_size(window, &w, &h);

        if ((root_x >= x && root_x <= x + w) && (root_y >= y && root_y <= y + h)) {
                return TRUE;
        }
        return FALSE;
}

/**
 * budgie_popover_manager_get_popover_for_coords:
 *
 * After having received an enter notify event and determining that it isn't
 * a BudgiePopover that we entered, we iterate our registered widgets and try
 * to find the one matching the X, Y coordinates.
 *
 * Upon finding a matching widget, we'll return the associated popover.
 */
static BudgiePopover *budgie_popover_manager_get_popover_for_coords(BudgiePopoverManager *self,
                                                                    gint root_x, gint root_y)
{
        GHashTableIter iter = { 0 };
        GtkWidget *parent_widget = NULL;
        BudgiePopover *assoc_popover = NULL;

        g_hash_table_iter_init(&iter, self->popovers);
        while (g_hash_table_iter_next(&iter, (void **)&parent_widget, (void **)&assoc_popover)) {
                GtkAllocation alloc = { 0 };
                GtkWidget *toplevel = NULL;
                GdkWindow *toplevel_window = NULL;
                gint rx, ry = 0;
                gint x, y = 0;

                /* Determine the parent_widget's absolute x, y on screen */
                toplevel = gtk_widget_get_toplevel(parent_widget);
                toplevel_window = gtk_widget_get_window(toplevel);
                gdk_window_get_position(toplevel_window, &x, &y);
                gtk_widget_translate_coordinates(parent_widget, toplevel, x, y, &rx, &ry);
                gtk_widget_get_allocation(parent_widget, &alloc);

                if ((root_x >= rx && root_x <= rx + alloc.width) &&
                    (root_y >= ry && root_y <= ry + alloc.height)) {
                        return assoc_popover;
                }
        }

        return NULL;
}

/**
 * budgie_popover_manager_popover_mapped:
 *
 * Handle the BudgiePopover becoming visible on screen, updating our knowledge
 * of who the currently active popover is
 */
static gboolean budgie_popover_manager_popover_mapped(BudgiePopover *popover,
                                                      __budgie_unused__ GdkEvent *event,
                                                      BudgiePopoverManager *self)
{
        self->active_popover = popover;
        return GDK_EVENT_PROPAGATE;
}

/**
 * budgie_popover_manager_popover_unmapped:
 *
 * Handle the BudgiePopover becoming invisible on screen, updating our knowledge
 * of who the currently active popover is
 */
static gboolean budgie_popover_manager_popover_unmapped(BudgiePopover *popover,
                                                        __budgie_unused__ GdkEvent *event,
                                                        BudgiePopoverManager *self)
{
        if (popover == self->active_popover) {
                self->active_popover = NULL;
        }
        return GDK_EVENT_PROPAGATE;
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
