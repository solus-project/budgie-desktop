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
#include <nm-client.h>
BUDGIE_END_PEDANTIC

struct _BudgieNetworkAppletClass {
        BudgieAppletClass parent_class;
};

struct _BudgieNetworkApplet {
        BudgieApplet parent;
        GtkWidget *popover;
        GtkWidget *image;
        NMClient *client;
};

G_DEFINE_DYNAMIC_TYPE_EXTENDED(BudgieNetworkApplet, budgie_network_applet, BUDGIE_TYPE_APPLET, 0, )

/**
 * Forward declarations
 */
static void budgie_network_applet_ready(GObject *source, GAsyncResult *res, gpointer v);

/**
 * Handle cleanup
 */
static void budgie_network_applet_dispose(GObject *object)
{
        BudgieNetworkApplet *self = BUDGIE_NETWORK_APPLET(object);

        /* Clean up our client */
        g_clear_object(&self->client);

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

        /* Start talking to the network manager */
        nm_client_new_async(NULL, budgie_network_applet_ready, self);
}

/**
 * budgie_network_applet_ready:
 *
 * We've got our NMClient on the async callback
 */
static void budgie_network_applet_ready(__budgie_unused__ GObject *source, GAsyncResult *res,
                                        gpointer v)
{
        GError *error = NULL;
        NMClient *client = NULL;
        BudgieNetworkApplet *self = v;

        /* Handle the errors */
        client = nm_client_new_finish(res, &error);
        if (error) {
                gchar *sprint_text =
                    g_strdup_printf("Failed to contact Network Manager: %s", error->message);
                g_message("Unable to obtain network client: %s", error->message);
                gtk_widget_set_tooltip_text(GTK_WIDGET(self), sprint_text);
                g_free(sprint_text);
                gtk_image_set_from_icon_name(GTK_IMAGE(self->image),
                                             "dialog-error-symbolic",
                                             GTK_ICON_SIZE_BUTTON);
                g_error_free(error);
                return;
        }

        /* We've got our client */
        self->client = client;
        g_message("Debug: Have client");
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
