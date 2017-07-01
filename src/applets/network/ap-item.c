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
#include "ap-item.h"
#include "common.h"
#include <glib/gi18n.h>
#include <nm-access-point.h>
#include <nm-utils.h>
BUDGIE_END_PEDANTIC

struct _BudgieAccessPointItemClass {
        GtkBoxClass parent_class;
};

struct _BudgieAccessPointItem {
        GtkBox parent;
        NMAccessPoint *access_point;

        GtkWidget *label;
};

G_DEFINE_DYNAMIC_TYPE_EXTENDED(BudgieAccessPointItem, budgie_access_point_item, GTK_TYPE_BOX, 0, )

enum { PROP_ACCESS_POINT = 1, N_PROPS };

static GParamSpec *obj_properties[N_PROPS] = {
        NULL,
};

/**
 * Forward declarations
 */
static void budgie_access_point_item_constructed(GObject *obj);
static void budgie_access_point_item_set_property(GObject *object, guint id, const GValue *value,
                                                  GParamSpec *spec);
static void budgie_access_point_item_get_property(GObject *object, guint id, GValue *value,
                                                  GParamSpec *spec);
static void budgie_access_point_item_update_label(BudgieAccessPointItem *self);

/**
 * Handle cleanup
 */
static void budgie_access_point_item_dispose(GObject *object)
{
        G_OBJECT_CLASS(budgie_access_point_item_parent_class)->dispose(object);
}

/**
 * Class initialisation
 */
static void budgie_access_point_item_class_init(BudgieAccessPointItemClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        /* gobject vtable hookup */
        obj_class->dispose = budgie_access_point_item_dispose;
        obj_class->constructed = budgie_access_point_item_constructed;
        obj_class->get_property = budgie_access_point_item_get_property;
        obj_class->set_property = budgie_access_point_item_set_property;

        obj_properties[PROP_ACCESS_POINT] =
            g_param_spec_pointer("access-point",
                                 "The associated access point",
                                 "A wifi access point",
                                 G_PARAM_CONSTRUCT | G_PARAM_READWRITE);
        g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

/**
 * We have no cleaning ourselves to do
 */
static void budgie_access_point_item_class_finalize(
    __budgie_unused__ BudgieAccessPointItemClass *klazz)
{
}

static void budgie_access_point_item_set_property(GObject *object, guint id, const GValue *value,
                                                  GParamSpec *spec)
{
        BudgieAccessPointItem *self = BUDGIE_ACCESS_POINT_ITEM(object);

        switch (id) {
        case PROP_ACCESS_POINT:
                self->access_point = g_value_get_pointer(value);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

static void budgie_access_point_item_get_property(GObject *object, guint id, GValue *value,
                                                  GParamSpec *spec)
{
        BudgieAccessPointItem *self = BUDGIE_ACCESS_POINT_ITEM(object);

        switch (id) {
        case PROP_ACCESS_POINT:
                g_value_set_pointer(value, self->access_point);
                break;
        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                break;
        }
}

/**
 * Initialisation of basic UI layout and such
 */
static void budgie_access_point_item_init(BudgieAccessPointItem *self)
{
        GtkWidget *label = NULL;

        /* Display label */
        label = gtk_label_new("");
        self->label = label;
        gtk_widget_set_halign(label, GTK_ALIGN_START);
        gtk_widget_set_margin_end(label, 12);
        gtk_widget_set_margin_start(label, 8);
        gtk_box_pack_start(GTK_BOX(self), label, FALSE, FALSE, 0);

        gtk_widget_show_all(GTK_WIDGET(self));
}

/**
 * budgie_access_point_item_update_label:
 *
 * Update our display label with the new SSID
 */
static void budgie_access_point_item_update_label(BudgieAccessPointItem *self)
{
        const GByteArray *ap_ssid = nm_access_point_get_ssid(self->access_point);
        autofree(gchar) *ssid = NULL;

        ssid = nm_utils_ssid_to_utf8(ap_ssid);

        gtk_label_set_text(GTK_LABEL(self->label), ssid);
}

static void budgie_access_point_item_constructed(GObject *obj)
{
        BudgieAccessPointItem *self = BUDGIE_ACCESS_POINT_ITEM(obj);

        /* Update display label */
        budgie_access_point_item_update_label(self);
}

GtkWidget *budgie_access_point_item_new(NMAccessPoint *ap)
{
        return g_object_new(BUDGIE_TYPE_ACCESS_POINT_ITEM,
                            "orientation",
                            GTK_ORIENTATION_HORIZONTAL,
                            "spacing",
                            0,
                            "access-point",
                            ap,
                            NULL);
}

void budgie_access_point_item_init_gtype(GTypeModule *module)
{
        budgie_access_point_item_register_type(module);
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
