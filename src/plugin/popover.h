/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
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

typedef struct _BudgiePopover BudgiePopover;
typedef struct _BudgiePopoverClass BudgiePopoverClass;
typedef struct _BudgiePopoverPrivate BudgiePopoverPrivate;

/**
 * BudgiePopoverClass:
 * @closed: Virtual closed signal
 */
struct _BudgiePopoverClass {
	GtkWindowClass parent_class;

	/* Marked for gtk-doc syntax */
	void (*closed)(BudgiePopover* popover);

	gpointer padding[12];
};

struct _BudgiePopover {
	GtkWindow parent;
	BudgiePopoverPrivate* priv;
};

/**
 * BudgiePopoverPositionPolicy:
 * @BUDGIE_POPOVER_POSITION_AUTOMATIC: Determine location based on the screen estate
 * @BUDGIE_POPOVER_POSITION_TOPLEVEL_HINT: Use hints on widgets parent window
 *
 * The BudgiePopoverPositionPolicy determines how the #BudgiePopover will be
 * placed on screen. The default policy (AUTOMATIC) will try to place the
 * popover at a sensible location relative to the parent widget, and point
 * the tail accordingly.
 *
 * The TOPLEVEL_HINT policy is designed for use with panels + docks, where the
 * top level window owning the relative-to widget sets a CSS class on itself
 * in accordance with the screen edge, i.e. top, left, bottom, right.
 */
typedef enum {
	BUDGIE_POPOVER_POSITION_AUTOMATIC = 0,
	BUDGIE_POPOVER_POSITION_TOPLEVEL_HINT,
} BudgiePopoverPositionPolicy;

#define BUDGIE_TYPE_POPOVER budgie_popover_get_type()
#define BUDGIE_POPOVER(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_POPOVER, BudgiePopover))
#define BUDGIE_IS_POPOVER(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_POPOVER))
#define BUDGIE_POPOVER_CLASS(o) (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_POPOVER, BudgiePopoverClass))
#define BUDGIE_IS_POPOVER_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_POPOVER))
#define BUDGIE_POPOVER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_POPOVER, BudgiePopoverClass))

/*
 * API Methods
 */

GtkWidget* budgie_popover_new(GtkWidget* relative_to);

void budgie_popover_set_position_policy(BudgiePopover* popover, BudgiePopoverPositionPolicy policy);
BudgiePopoverPositionPolicy budgie_popover_get_position_policy(BudgiePopover* popover);

GType budgie_popover_get_type(void);

G_END_DECLS
