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

#include "popover-manager.h"

G_BEGIN_DECLS

#define BUDGIE_APPLET_KEY_NAME "name"
#define BUDGIE_APPLET_KEY_ALIGN "alignment"
#define BUDGIE_APPLET_KEY_POS "position"

/**
 * BudgiePanelAction:
 * @BUDGIE_PANEL_ACTION_MENU: Invoke the menu action
 *
 * BudgiePanelAction's are bitwise OR'd so that a #BudgieApplet may expose
 * the actions that it supports, when the panel is interacted with in
 * a global fashion (such as via the D-BUS API)
 */
typedef enum {
	BUDGIE_PANEL_ACTION_NONE = 1 << 0,
	BUDGIE_PANEL_ACTION_MENU = 1 << 1,
	BUDGIE_PANEL_ACTION_MAX = 1 << 2
} BudgiePanelAction;

/**
 * BudgiePanelPosition:
 * @BUDGIE_PANEL_POSITION_NONE: No position is yet assigned
 * @BUDGIE_PANEL_POSITION_BOTTOM: The bottom edge has been assigned
 * @BUDGIE_PANEL_POSITION_TOP: The top edge has been assigned
 * @BUDGIE_PANEL_POSITION_LEFT: The left edge has been assigned
 * @BUDGIE_PANEL_POSITION_RIGHT: The right edge has been assigned
 *
 * Each applet lives on a unique panel which can live on any one of
 * the 4 screen edges. Internally this is represented with a bitmask
 * to enable efficient screen management.
 */
typedef enum {
	BUDGIE_PANEL_POSITION_NONE = 1 << 0,
	BUDGIE_PANEL_POSITION_BOTTOM = 1 << 1,
	BUDGIE_PANEL_POSITION_TOP = 1 << 2,
	BUDGIE_PANEL_POSITION_LEFT = 1 << 3,
	BUDGIE_PANEL_POSITION_RIGHT = 1 << 4
} BudgiePanelPosition;

typedef struct _BudgieAppletPrivate BudgieAppletPrivate;
typedef struct _BudgieApplet BudgieApplet;
typedef struct _BudgieAppletClass BudgieAppletClass;

#define BUDGIE_TYPE_APPLET budgie_applet_get_type()
#define BUDGIE_APPLET(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_APPLET, BudgieApplet))
#define BUDGIE_IS_APPLET(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_APPLET))
#define BUDGIE_APPLET_CLASS(o) (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_APPLET, BudgieAppletClass))
#define BUDGIE_IS_APPLET_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_APPLET))
#define BUDGIE_APPLET_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_APPLET, BudgieAppletClass))

/**
 * BudgieAppletClass:
 * @invoke_action: Virtual invoke_action function
 * @supports_settings: Virtual supports_settings function
 * @get_settings_ui: Virtual get_settings_ui function
 * @panel_size_changed: Virtual panel_size_changed function
 * @update_popovers: Virtual update_popovers method
 */
struct _BudgieAppletClass {
	GtkEventBoxClass parent_class;

	void (*invoke_action)(BudgieApplet* self, BudgiePanelAction action);
	gboolean (*supports_settings)(BudgieApplet* self);
	GtkWidget* (*get_settings_ui)(BudgieApplet* self);
	void (*panel_size_changed)(BudgieApplet* applet, int panel_size, int icon_size, int small_icon_size);
	void (*panel_position_changed)(BudgieApplet* applet, BudgiePanelPosition position);
	void (*update_popovers)(BudgieApplet* applet, BudgiePopoverManager* manager);

	gpointer padding[12];
};

struct _BudgieApplet {
	GtkEventBox parent_instance;
	BudgieAppletPrivate* priv;
};

BudgieApplet* budgie_applet_new(void);

void budgie_applet_invoke_action(BudgieApplet* self, BudgiePanelAction action);
gboolean budgie_applet_supports_settings(BudgieApplet* self);
GtkWidget* budgie_applet_get_settings_ui(BudgieApplet* self);
GSettings* budgie_applet_get_applet_settings(BudgieApplet* self, gchar* uuid);

void budgie_applet_set_settings_schema(BudgieApplet* self, const gchar* schema);
const gchar* budgie_applet_get_settings_schema(BudgieApplet* self);

void budgie_applet_set_settings_prefix(BudgieApplet* self, const gchar* prefix);
const gchar* budgie_applet_get_settings_prefix(BudgieApplet* self);

void budgie_applet_update_popovers(BudgieApplet* self, BudgiePopoverManager* manager);

BudgiePanelAction budgie_applet_get_supported_actions(BudgieApplet* self);

GType budgie_applet_get_type(void);

G_END_DECLS
