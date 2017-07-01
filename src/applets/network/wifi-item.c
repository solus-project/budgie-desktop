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
#include "common.h"
#include "wifi-item.h"
#include <glib/gi18n.h>
BUDGIE_END_PEDANTIC

struct _BudgieWifiItemClass {
        GtkBoxClass parent_class;
};

struct _BudgieWifiItem {
        GtkBox parent;
        NMDevice *device;

        gint index;
        GtkWidget *image;
        GtkWidget *label;
        GtkWidget *switch_active;
};

G_DEFINE_DYNAMIC_TYPE_EXTENDED(BudgieWifiItem, budgie_wifi_item, GTK_TYPE_BOX, 0, )

enum { PROP_DEVICE = 1, PROP_INDEX = 2, N_PROPS };

static GParamSpec *obj_properties[N_PROPS] = {
        NULL,
};

/**
 * Forward declarations
 */
static void budgie_wifi_item_constructed(GObject *obj);
static void budgie_wifi_item_set_property(GObject *object, guint id, const GValue *value,
                                          GParamSpec *spec);
static void budgie_wifi_item_get_property(GObject *object, guint id, GValue *value,
                                          GParamSpec *spec);
static void budgie_wifi_item_switched(GObject *o, GParamSpec *ps, BudgieWifiItem *self);

/**
 * Handle cleanup
 */
static void budgie_wifi_item_dispose(GObject *object)
{
        G_OBJECT_CLASS(budgie_wifi_item_parent_class)->dispose(object);
}

/**
 * Class initialisation
 */
static void budgie_wifi_item_class_init(BudgieWifiItemClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable hookup */
        obj_class->dispose = budgie_wifi_item_dispose;
        obj_class->constructed = budgie_wifi_item_constructed;
        obj_class->get_property = budgie_wifi_item_get_property;
        obj_class->set_property = budgie_wifi_item_set_property;

        obj_properties[PROP_DEVICE] = g_param_spec_pointer("device",
                                                           "The associated network device",
                                                           "An wifi device",
                                                           G_PARAM_CONSTRUCT | G_PARAM_READWRITE);

        obj_properties[PROP_INDEX] = g_param_spec_int("device-index",
                                                      "Index of this device type",
                                                      "Number of this wifi connection",
                                                      0,
                                                      G_MAXINT,
                                                      0,
                                                      G_PARAM_CONSTRUCT | G_PARAM_READWRITE);
        g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

/**
 * We have no cleaning ourselves to do
 */
static void budgie_wifi_item_class_finalize(__budgie_unused__ BudgieWifiItemClass *klazz)
{
}

static void budgie_wifi_item_set_property(GObject *object, guint id, const GValue *value,
                                          GParamSpec *spec)
{
        BudgieWifiItem *self = BUDGIE_WIFI_ITEM(object);

        switch (id) {
        case PROP_DEVICE:
                self->device = g_value_get_pointer(value);
                break;
        case PROP_INDEX:
                self->index = g_value_get_int(value);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

static void budgie_wifi_item_get_property(GObject *object, guint id, GValue *value,
                                          GParamSpec *spec)
{
        BudgieWifiItem *self = BUDGIE_WIFI_ITEM(object);

        switch (id) {
        case PROP_DEVICE:
                g_value_set_pointer(value, self->device);
                break;
        case PROP_INDEX:
                g_value_set_int(value, self->index);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

/**
 * Initialisation of basic UI layout and such
 */
static void budgie_wifi_item_init(BudgieWifiItem *self)
{
        GtkWidget *image = NULL;
        GtkWidget *label = NULL;
        GtkWidget *switch_active = NULL;
        GtkWidget *header_layout = NULL;

        header_layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_box_pack_start(GTK_BOX(self), header_layout, FALSE, FALSE, 0);

        /* Display image */
        image = gtk_image_new();
        self->image = image;
        gtk_image_set_pixel_size(GTK_IMAGE(image), 16);
        gtk_box_pack_start(GTK_BOX(header_layout), image, FALSE, FALSE, 0);
        gtk_widget_set_margin_end(image, 12);
        gtk_widget_set_halign(image, GTK_ALIGN_START);

        /* Display label */
        label = gtk_label_new("");
        self->label = label;
        gtk_widget_set_halign(label, GTK_ALIGN_START);
        gtk_widget_set_margin_end(label, 6);
        gtk_box_pack_start(GTK_BOX(header_layout), label, FALSE, FALSE, 0);

        /* Allow turning on/off the connection */
        switch_active = gtk_switch_new();
        self->switch_active = switch_active;
        gtk_box_pack_end(GTK_BOX(header_layout), switch_active, FALSE, FALSE, 0);

        gtk_widget_show_all(GTK_WIDGET(self));
}

static void budgie_wifi_item_constructed(GObject *obj)
{
        BudgieWifiItem *self = BUDGIE_WIFI_ITEM(obj);
        autofree(gchar) *label = NULL;

        if (self->index > 0) {
                label = g_strdup_printf(_("Wi-Fi connection %d"), self->index + 1);
        } else {
                label = g_strdup_printf(_("Wi-Fi connection"));
        }

        /* Update our display label */
        gtk_label_set_text(GTK_LABEL(self->label), label);
}

GtkWidget *budgie_wifi_item_new(NMDevice *device, gint index)
{
        return g_object_new(BUDGIE_TYPE_WIFI_ITEM,
                            "orientation",
                            GTK_ORIENTATION_VERTICAL,
                            "spacing",
                            0,
                            "device",
                            device,
                            "device-index",
                            index,
                            NULL);
}

void budgie_wifi_item_init_gtype(GTypeModule *module)
{
        budgie_wifi_item_register_type(module);
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
