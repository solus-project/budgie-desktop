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

#include <applet-info.h>
#include <applet.h>
#include <budgie-enums.h>
#include <popover-manager.h>
#include <popover.h>

G_BEGIN_DECLS

typedef struct _BudgiePlugin BudgiePlugin;
typedef struct _BudgiePluginIface BudgiePluginIface;

#define BUDGIE_TYPE_PLUGIN (budgie_plugin_get_type())
#define BUDGIE_PLUGIN(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_PLUGIN, BudgiePlugin))
#define BUDGIE_IS_PLUGIN(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_PLUGIN))
#define BUDGIE_PLUGIN_IFACE(o) (G_TYPE_CHECK_INTERFACE_CAST((o), BUDGIE_TYPE_PLUGIN, BudgiePluginIface))
#define BUDGIE_IS_PLUGIN_IFACE(o) (G_TYPE_CHECK_INTERFACE_TYPE((o), BUDGIE_TYPE_PLUGIN))
#define BUDGIE_PLUGIN_GET_IFACE(o) (G_TYPE_INSTANCE_GET_INTERFACE((o), BUDGIE_TYPE_PLUGIN, BudgiePluginIface))

/**
 * BudgiePluginIface
 */
struct _BudgiePluginIface {
	GTypeInterface parent_iface;

	BudgieApplet* (*get_panel_widget)(BudgiePlugin* self, gchar* uuid);

	gpointer padding[4];
};

BudgieApplet* budgie_plugin_get_panel_widget(BudgiePlugin* self, gchar* uuid);

GType budgie_plugin_get_type(void);

G_END_DECLS
