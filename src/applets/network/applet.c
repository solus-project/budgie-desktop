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

#include "applet.h"

struct _BudgieNetworkAppletClass {
        BudgieAppletClass parent_class;
};

struct _BudgieNetworkApplet {
        BudgieApplet parent;
        GtkWidget *popover;
        GtkWidget *image;
};

G_DEFINE_DYNAMIC_TYPE_EXTENDED(BudgieNetworkApplet, budgie_network_applet, BUDGIE_TYPE_APPLET, 0, )

/**
 * Handle cleanup
 */
static void budgie_network_applet_dispose(GObject *object)
{
        G_OBJECT_CLASS(budgie_network_applet_parent_class)->dispose(object);
}

/**
 * Class initialisation
 */
static void budgie_network_applet_class_init(BudgieNetworkAppletClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable hookup */
        obj_class->dispose = budgie_network_applet_dispose;
}

/**
 * We have no cleaning ourselves to do
 */
static void budgie_network_applet_class_finalize(__budgie_unused__ BudgieNetworkAppletClass *klazz)
{
}

/**
 * Initialisation of basic UI layout and such
 */
static void budgie_network_applet_init(BudgieNetworkApplet *self)
{
        GtkWidget *image = NULL;
        GtkWidget *box = NULL;
        GtkStyleContext *style = NULL;

        style = gtk_widget_get_style_context(GTK_WIDGET(self));
        gtk_style_context_add_class(style, "network-applet");

        box = gtk_event_box_new();
        gtk_container_add(GTK_CONTAINER(self), box);

        /* Default to disconnected icon */
        image = gtk_image_new_from_icon_name("network-offline-symbolic", GTK_ICON_SIZE_BUTTON);
        self->image = image;
        gtk_container_add(GTK_CONTAINER(box), image);

        /* TODO: Hook up signals and popovers and what not */

        /* Show up on screen */
        gtk_widget_show_all(GTK_WIDGET(self));
}

void budgie_network_applet_init_gtype(GTypeModule *module)
{
        budgie_network_applet_register_type(module);
}

BudgieApplet *budgie_network_applet_new(void)
{
        return g_object_new(BUDGIE_TYPE_NETWORK_APPLET, NULL);
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
