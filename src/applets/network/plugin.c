/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#define _GNU_SOURCE

#include "util.h"

BUDGIE_BEGIN_PEDANTIC
#include "applet.h"
#include "ethernet-item.h"
#include "plugin.h"
#include <budgie-desktop/plugin.h>
BUDGIE_END_PEDANTIC

static void budgie_network_plugin_iface_init(BudgiePluginIface *iface);

G_DEFINE_DYNAMIC_TYPE_EXTENDED(BudgieNetworkPlugin, budgie_network_plugin, G_TYPE_OBJECT, 0,
                               G_IMPLEMENT_INTERFACE_DYNAMIC(BUDGIE_TYPE_PLUGIN,
                                                             budgie_network_plugin_iface_init))

/**
 * Return a new panel widget
 */
static BudgieApplet *native_applet_get_panel_widget(__budgie_unused__ BudgiePlugin *self,
                                                    __budgie_unused__ gchar *uuid)
{
        return budgie_network_applet_new();
}

/**
 * Handle cleanup
 */
static void budgie_network_plugin_dispose(GObject *object)
{
        G_OBJECT_CLASS(budgie_network_plugin_parent_class)->dispose(object);
}

/**
 * Class initialisation
 */
static void budgie_network_plugin_class_init(BudgieNetworkPluginClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable hookup */
        obj_class->dispose = budgie_network_plugin_dispose;
}

/**
 * Implement the BudgiePlugin interface, i.e the factory method get_panel_widget
 */
static void budgie_network_plugin_iface_init(BudgiePluginIface *iface)
{
        iface->get_panel_widget = native_applet_get_panel_widget;
}

/**
 * No-op, just skips compiler errors
 */
static void budgie_network_plugin_init(__budgie_unused__ BudgieNetworkPlugin *self)
{
}

/**
 * We have no cleaning ourselves to do
 */
static void budgie_network_plugin_class_finalize(__budgie_unused__ BudgieNetworkPluginClass *klazz)
{
}

/**
 * Export the types to the gobject type system
 */
G_MODULE_EXPORT void peas_register_types(PeasObjectModule *module)
{
        budgie_network_plugin_register_type(G_TYPE_MODULE(module));

        /* Register the actual dynamic types contained in the resulting plugin */
        budgie_network_applet_init_gtype(G_TYPE_MODULE(module));
        budgie_ethernet_item_init_gtype(G_TYPE_MODULE(module));

        peas_object_module_register_extension_type(module,
                                                   BUDGIE_TYPE_PLUGIN,
                                                   BUDGIE_TYPE_NETWORK_PLUGIN);
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
