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

#include "plugin.h"

typedef BudgiePluginIface BudgiePluginInterface;

G_DEFINE_INTERFACE(BudgiePlugin, budgie_plugin, G_TYPE_OBJECT)

static void budgie_plugin_default_init(__attribute__ ((unused)) BudgiePluginIface *iface)
{
}

/**
 * budgie_plugin_get_panel_widget:
 * @uuid UUID for this new instance
 *
 * Returns: (transfer full): A newly initialised panel widget
 */
BudgieApplet *budgie_plugin_get_panel_widget(BudgiePlugin *self, gchar *uuid)
{
        if (!self) {
                return NULL;
        }
        return BUDGIE_PLUGIN_GET_IFACE(self)->get_panel_widget(self, uuid);
}
