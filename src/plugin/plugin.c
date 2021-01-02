/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include "plugin.h"

/**
 * SECTION:plugin
 * @Short_description: Main entry point for Budgie Panel Applets
 * @Title: BudgiePlugin
 *
 * The BudgiePlugin provides the main entry point for modules that wish
 * to extend the functionality of the Budgie Panel. In reality, the vast
 * majority of the work is actually implemented in #BudgieApplet.
 *
 * Implementations must implement the #budgie_plugin_get_panel_widget method,
 * and provide a new instance of their implementation of the BudgieApplet:
 * |[<!-- language="C" -->
 *
 *      static BudgieApplet *my_type_get_panel_widget(BudgiePlugin *self, gchar *uuid)
 *      {
 *              return my_applet_new(uuid);
 *      }
 *
 *      static void my_class_init(GObjectClass *klass)
 *      {
 *              MyClass *mc = MY_CLASS(klass);
 *              ...
 *              mc->get_panel_widget = my_type_get_panel_widget;
 *      }
 * ]|
 *
 * In Vala we would achieve like so:
 *
 * |[<!-- language="Vala" -->
 *
 *      public Budgie.Applet get_panel_widget(string uuid)
 *      {
 *          return new MyApplet();
 *      }
 * ]|
 */

typedef BudgiePluginIface BudgiePluginInterface;

G_DEFINE_INTERFACE(BudgiePlugin, budgie_plugin, G_TYPE_OBJECT)

static void budgie_plugin_default_init(__attribute__((unused)) BudgiePluginIface* iface) {
}

/**
 * budgie_plugin_get_panel_widget:
 * @self: A #BudgiePlugin
 * @uuid: UUID for this new instance
 *
 * Returns: (transfer full): A newly initialised panel widget
 */
BudgieApplet* budgie_plugin_get_panel_widget(BudgiePlugin* self, gchar* uuid) {
	if (!self) {
		return NULL;
	}
	return BUDGIE_PLUGIN_GET_IFACE(self)->get_panel_widget(self, uuid);
}
