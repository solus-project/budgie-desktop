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

#define _GNU_SOURCE

#include "util.h"

BUDGIE_BEGIN_PEDANTIC
#include "popover-manager.h"
#include <gtk/gtk.h>
BUDGIE_END_PEDANTIC

struct _BudgiePopoverManagerPrivate {
	GHashTable* popovers;
	BudgiePopover* active_popover;
	gboolean grabbed;
};

G_DEFINE_TYPE_WITH_PRIVATE(BudgiePopoverManager, budgie_popover_manager, G_TYPE_OBJECT)

#if !GTK_CHECK_VERSION(3, 20, 0)
/*
 * Borrowed from brisk's popover-manager.c (in turn borrowed from) gdkseatdefault.c
 */
#define KEYBOARD_EVENTS (GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK | GDK_FOCUS_CHANGE_MASK)
#define POINTER_EVENTS (GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK | GDK_SCROLL_MASK |    \
						GDK_SMOOTH_SCROLL_MASK | GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_PROXIMITY_IN_MASK | \
						GDK_PROXIMITY_OUT_MASK)
#endif

static void budgie_popover_manager_link_signals(BudgiePopoverManager* manager, GtkWidget* parent_widget, BudgiePopover* popover);
static void budgie_popover_manager_unlink_signals(BudgiePopoverManager* manager, GtkWidget* parent_widget, BudgiePopover* popover);
static gboolean budgie_popover_manager_popover_mapped(BudgiePopover* popover, GdkEvent* event, BudgiePopoverManager* self);
static gboolean budgie_popover_manager_popover_unmapped(BudgiePopover* popover, GdkEvent* event, BudgiePopoverManager* self);
static void budgie_popover_manager_grab_notify(BudgiePopoverManager* self, gboolean was_grabbed, BudgiePopover* popover);
static gboolean budgie_popover_manager_grab_broken(BudgiePopoverManager* self, GdkEvent* event, BudgiePopover* popover);
static void budgie_popover_manager_grab(BudgiePopoverManager* self, BudgiePopover* popover);
static void budgie_popover_manager_ungrab(BudgiePopoverManager* self, BudgiePopover* popover);
/**
 * budgie_popover_manager_new:

 * Construct a new BudgiePopoverManager object
 *
 * Return value: A pointer to a new #BudgiePopoverManager object.
 */
BudgiePopoverManager* budgie_popover_manager_new() {
	return g_object_new(BUDGIE_TYPE_POPOVER_MANAGER, NULL);
}

/**
 * budgie_popover_manager_dispose:
 *
 * Clean up a BudgiePopoverManager instance
 */
static void budgie_popover_manager_dispose(GObject* obj) {
	BudgiePopoverManager* self = NULL;

	self = BUDGIE_POPOVER_MANAGER(obj);
	g_clear_pointer(&self->priv->popovers, g_hash_table_unref);

	G_OBJECT_CLASS(budgie_popover_manager_parent_class)->dispose(obj);
}

/**
 * budgie_popover_manager_class_init:
 *
 * Handle class initialisation
 */
static void budgie_popover_manager_class_init(BudgiePopoverManagerClass* klazz) {
	GObjectClass* obj_class = G_OBJECT_CLASS(klazz);

	/* gobject vtable hookup */
	obj_class->dispose = budgie_popover_manager_dispose;
}

/**
 * budgie_popover_manager_init:
 *
 * Handle construction of the BudgiePopoverManager
 */
static void budgie_popover_manager_init(BudgiePopoverManager* self) {
	self->priv = budgie_popover_manager_get_instance_private(self);
	self->priv->grabbed = FALSE;

	/* We don't re-ref anything as we just effectively hold floating references
	 * to the WhateverTheyAres
	 */
	self->priv->popovers = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, NULL);
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
void budgie_popover_manager_register_popover(BudgiePopoverManager* self, GtkWidget* parent_widget, BudgiePopover* popover) {
	g_assert(self != NULL);
	g_return_if_fail(parent_widget != NULL && popover != NULL);

	if (g_hash_table_contains(self->priv->popovers, parent_widget)) {
		g_warning("register_popover(): Widget %p is already registered", (gpointer) parent_widget);
		return;
	}

	/* We're a popover manager, so we're meant for use in some kind of panel
	 * situation. Use toplevel hints for better positioning */
	budgie_popover_set_position_policy(popover, BUDGIE_POPOVER_POSITION_TOPLEVEL_HINT);

	/* Stick it into the map and hook it up */
	budgie_popover_manager_link_signals(self, parent_widget, popover);
	g_hash_table_insert(self->priv->popovers, parent_widget, popover);
}

/**
 * budgie_popover_manager_unregister_popover:
 * @parent_widget: The associated widget (key) for the registered popover
 *
 * Unregister a popover so that it is no longer managed by this implementation,
 * and is free to manage itself.
 */
void budgie_popover_manager_unregister_popover(BudgiePopoverManager* self, GtkWidget* parent_widget) {
	g_assert(self != NULL);
	g_return_if_fail(parent_widget != NULL);
	BudgiePopover* popover = NULL;

	popover = g_hash_table_lookup(self->priv->popovers, parent_widget);
	if (!popover) {
		g_warning("unregister_popover(): Widget %p is unknown", (gpointer) parent_widget);
		return;
	}

	budgie_popover_manager_unlink_signals(self, parent_widget, popover);
	g_hash_table_remove(self->priv->popovers, parent_widget);
}

/**
 * show_one_popover:
 *
 * Show a popover on the idle loop to prevent any weird event locks
 */
static gboolean show_one_popover(gpointer v) {
	if (gtk_grab_get_current()) {
		return FALSE;
	}

	gtk_widget_show(GTK_WIDGET(v));
	return FALSE;
}

/**
 * budgie_popover_manager_show_popover:
 * @parent_widget: The widget owning the popover to be shown
 *
 * Show a #BudgiePopover on screen belonging to the specified @parent_widget
 */
void budgie_popover_manager_show_popover(BudgiePopoverManager* self, GtkWidget* parent_widget) {
	BudgiePopover* popover = NULL;

	g_assert(self != NULL);
	g_return_if_fail(parent_widget != NULL);

	popover = g_hash_table_lookup(self->priv->popovers, parent_widget);
	if (!popover) {
		g_warning("show_popover(): Widget %p is unknown", (gpointer) parent_widget);
		return;
	}

	g_idle_add(show_one_popover, popover);
}

/**
 * budgie_popover_manager_widget_died:
 *
 * The widget has died, so remove it from our internal state
 */
static void budgie_popover_manager_widget_died(BudgiePopoverManager* self, GtkWidget* child) {
	if (!g_hash_table_contains(self->priv->popovers, child)) {
		return;
	}
	g_hash_table_remove(self->priv->popovers, child);
}

/**
 * budgie_popover_manager_link_signals:
 *
 * Hook up the various signals we need to manage this popover correctly
 */
static void budgie_popover_manager_link_signals(BudgiePopoverManager* self, GtkWidget* parent_widget, BudgiePopover* popover) {
	g_signal_connect_swapped(parent_widget, "destroy", G_CALLBACK(budgie_popover_manager_widget_died), self);

	/* Monitor map/unmap to manage the grab semantics */
	g_signal_connect(popover, "map-event", G_CALLBACK(budgie_popover_manager_popover_mapped), self);
	g_signal_connect(popover, "unmap-event", G_CALLBACK(budgie_popover_manager_popover_unmapped), self);

	/* Determine when a re-grab is needed */
	g_signal_connect_swapped(popover, "grab-notify", G_CALLBACK(budgie_popover_manager_grab_notify), self);
	g_signal_connect_swapped(popover, "grab-broken-event", G_CALLBACK(budgie_popover_manager_grab_broken), self);
}

/**
 * budgie_popover_manager_unlink_signals:
 *
 * Disconnect any prior signals for this popover so we stop receiving events for it
 */
static void budgie_popover_manager_unlink_signals(BudgiePopoverManager* self, GtkWidget* parent_widget, BudgiePopover* popover) {
	g_signal_handlers_disconnect_by_data(parent_widget, self);
	g_signal_handlers_disconnect_by_data(popover, self);
}

/**
 * budgie_popover_manager_popover_mapped:
 *
 * Handle the BudgiePopover becoming visible on screen, updating our knowledge
 * of who the currently active popover is
 */
static gboolean budgie_popover_manager_popover_mapped(BudgiePopover* popover, __budgie_unused__ GdkEvent* event, BudgiePopoverManager* self) {
	/* Someone might have forcibly opened a new popover with one active, so
	 * if we're already managing a popover, the only sane thing to do is
	 * to tell it to sod off and start managing the new one.
	 */
	if (self->priv->active_popover && self->priv->active_popover != popover) {
		budgie_popover_manager_ungrab(self, self->priv->active_popover);
		self->priv->active_popover = NULL;
		if (gtk_widget_get_visible(GTK_WIDGET(popover))) {
			gtk_widget_hide(GTK_WIDGET(popover));
		}
	}

	self->priv->active_popover = popover;

	/* Don't attempt to steal grabs */
	if (gtk_grab_get_current()) {
		gtk_widget_hide(GTK_WIDGET(popover));
		self->priv->active_popover = NULL;
		self->priv->grabbed = FALSE;
		return GDK_EVENT_PROPAGATE;
	}

	/* If we don't do this weird cycle then the rollover enter-notify
	 * event becomes broken, defeating the purpose of a manager.
	 */
	budgie_popover_manager_grab(self, popover);
	budgie_popover_manager_ungrab(self, popover);
	budgie_popover_manager_grab(self, popover);

	return GDK_EVENT_PROPAGATE;
}

/**
 * budgie_popover_manager_popover_unmapped:
 *
 * Handle the BudgiePopover becoming invisible on screen, updating our knowledge
 * of who the currently active popover is
 */
static gboolean budgie_popover_manager_popover_unmapped(BudgiePopover* popover, __budgie_unused__ GdkEvent* event, BudgiePopoverManager* self) {
	budgie_popover_manager_ungrab(self, popover);

	if (popover == self->priv->active_popover) {
		self->priv->active_popover = NULL;
	}

	return GDK_EVENT_PROPAGATE;
}

/**
 * budgie_popover_manager_grab:
 *
 * Grab the input events using the GdkSeat
 */
static void budgie_popover_manager_grab(BudgiePopoverManager* self, BudgiePopover* popover) {
	GdkDisplay* display = NULL;
	GdkWindow* window = NULL;
	GdkGrabStatus st;

	if (self->priv->grabbed || popover != self->priv->active_popover) {
		return;
	}

	window = gtk_widget_get_window(GTK_WIDGET(popover));

	if (!window) {
		g_warning("Attempting to grab BudgiePopover when not realized");
		return;
	}

	display = gtk_widget_get_display(GTK_WIDGET(popover));

#if GTK_CHECK_VERSION(3, 20, 0)
	/* 3.20 and newer use GdkSeat API */
	GdkSeat* seat = NULL;
	GdkSeatCapabilities caps = GDK_SEAT_CAPABILITY_ALL;

	seat = gdk_display_get_default_seat(display);

	st = gdk_seat_grab(seat, window, caps, TRUE, NULL, NULL, NULL, NULL);
	if (st == GDK_GRAB_SUCCESS) {
		self->priv->grabbed = TRUE;
		gtk_grab_add(GTK_WIDGET(popover));
	}
#else
	/* Likely 3.18, use old GdkDevice API */
	GdkDeviceManager* manager = NULL;
	GdkDevice *pointer, *keyboard = NULL;

	manager = gdk_display_get_device_manager(display);

	pointer = gdk_device_manager_get_client_pointer(manager);
	keyboard = gdk_device_get_associated_device(pointer);

	st = gdk_device_grab(pointer, window, GDK_OWNERSHIP_NONE, TRUE, POINTER_EVENTS, NULL, GDK_CURRENT_TIME);

	if (st != GDK_GRAB_SUCCESS) {
		return;
	}
	if (keyboard) {
		st = gdk_device_grab(keyboard, window, GDK_OWNERSHIP_NONE, TRUE, KEYBOARD_EVENTS, NULL, GDK_CURRENT_TIME);
		if (st != GDK_GRAB_SUCCESS) {
			gdk_device_ungrab(keyboard, GDK_CURRENT_TIME);
			return;
		}
	}
	self->priv->grabbed = TRUE;
	gtk_grab_add(GTK_WIDGET(popover));
#endif
}

/**
 * budgie_popover_manager_ungrab:
 *
 * Ungrab a previous grab by this widget
 */
static void budgie_popover_manager_ungrab(BudgiePopoverManager* self, BudgiePopover* popover) {
	GdkDisplay* display = NULL;

	if (!self->priv->grabbed || popover != self->priv->active_popover) {
		return;
	}

	display = gtk_widget_get_display(GTK_WIDGET(popover));

#if GTK_CHECK_VERSION(3, 20, 0)
	/* 3.20 and newer use GdkSeat API */
	GdkSeat* seat = NULL;

	seat = gdk_display_get_default_seat(display);

	gtk_grab_remove(GTK_WIDGET(popover));
	gdk_seat_ungrab(seat);
	self->priv->grabbed = FALSE;
#else
	/* Likely 3.18 */
	GdkDeviceManager* manager = NULL;
	GdkDevice *pointer, *keyboard = NULL;

	manager = gdk_display_get_device_manager(display);

	pointer = gdk_device_manager_get_client_pointer(manager);
	keyboard = gdk_device_get_associated_device(pointer);

	gtk_grab_remove(GTK_WIDGET(popover));

	gdk_device_ungrab(pointer, GDK_CURRENT_TIME);
	if (keyboard) {
		gdk_device_ungrab(keyboard, GDK_CURRENT_TIME);
	}
	self->priv->grabbed = FALSE;
#endif
}

/**
 * budgie_popover_manager_grab_broken:
 *
 * Grab was broken, most likely due to a window within our application
 */
static gboolean budgie_popover_manager_grab_broken(BudgiePopoverManager* self, __budgie_unused__ GdkEvent* event, BudgiePopover* popover) {
	if (popover != self->priv->active_popover) {
		return GDK_EVENT_PROPAGATE;
	}

	self->priv->grabbed = FALSE;
	return GDK_EVENT_PROPAGATE;
}

/**
 * budgie_popover_manager_grab_notify:
 *
 * Grab changed _within_ the application
 *
 * If our grab was broken, i.e. due to some popup menu, and we're still visible,
 * we'll now try and grab focus once more.
 */
static void budgie_popover_manager_grab_notify(BudgiePopoverManager* self, gboolean was_grabbed, BudgiePopover* popover) {
	/* Only interested in unshadowed */
	if (!was_grabbed || popover != self->priv->active_popover) {
		return;
	}

	budgie_popover_manager_ungrab(self, popover);

	/* And being visible. ofc. */
	if (!gtk_widget_get_visible(GTK_WIDGET(popover))) {
		return;
	}

	/* Redo the whole grab cycle to restore proper enter-notify events */
	budgie_popover_manager_grab(self, popover);
	budgie_popover_manager_ungrab(self, popover);
	budgie_popover_manager_grab(self, popover);
}
