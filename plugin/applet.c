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

#include "applet.h"
#include "budgie-enums.h"


enum {
        PROP_PREFIX = 1,
        PROP_SCHEMA,
        PROP_ACTIONS,
        N_PROPS
};

enum {
        POSITION_CHANGED = 0,
        N_SIGNALS
};

struct _BudgieAppletPrivate {
        char *prefix;
        char *schema;
        BudgiePanelAction actions;
};

G_DEFINE_TYPE_WITH_PRIVATE(BudgieApplet, budgie_applet, GTK_TYPE_BIN);

static GParamSpec *obj_properties[N_PROPS] = { NULL, };
static guint applet_signals[N_SIGNALS] = { 0 };

#define FREE_IF_SET(x) { if (self->priv->x) { g_free(self->priv->x) ; self->priv->x = NULL; } }


static void budgie_applet_get_property(GObject *object, guint id,
                                        GValue *value, GParamSpec* spec)
{
        BudgieApplet *self = BUDGIE_APPLET(object);

        switch (id) {
                case PROP_PREFIX:
                        budgie_applet_set_settings_prefix(self, g_value_get_string(value));
                        break;
                case PROP_SCHEMA:
                        budgie_applet_set_settings_schema(self, g_value_get_string(value));
                        break;
                case PROP_ACTIONS:
                        self->priv->actions = g_value_get_enum(value);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                        break;
        }
                        
}

static void budgie_applet_set_property(GObject *object, guint id,
                                        const GValue *value, GParamSpec *spec)
{
        BudgieApplet *self = BUDGIE_APPLET(object);

        switch (id) {
                case PROP_PREFIX:
                        g_value_set_string((GValue*)value, budgie_applet_get_settings_prefix(self));
                        break;
                case PROP_SCHEMA:
                        g_value_set_string((GValue*)value, budgie_applet_get_settings_schema(self));
                        break;
                case PROP_ACTIONS:
                        g_value_set_flags((GValue*)value, self->priv->actions);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
                        break;
        }
}

/**
 * budgie_applet_invoke_action:
 * @action: Action to invoke
 *
 * Invoke the given action on this applet. This action will only be one
 * that has been declared in supported actions bitmask
 */
void budgie_applet_invoke_action(BudgieApplet *self, BudgiePanelAction action)
{
        BudgieAppletClass *klazz = NULL;

        if (!BUDGIE_IS_APPLET(self)) {
                return;
        }

        klazz = BUDGIE_APPLET_GET_CLASS(self);

        if (klazz->invoke_action) {
                klazz->invoke_action(self, action);
        }
}

/**
 * budgie_applet_supports_settings:
 *
 * Implementations should override this to return TRUE if they support
 * a settings UI
 */
gboolean budgie_applet_supports_settings(BudgieApplet *self)
{
        BudgieAppletClass *klazz = NULL;

        if (!BUDGIE_IS_APPLET(self)) {
                return FALSE;
        }

        klazz = BUDGIE_APPLET_GET_CLASS(self);
        if (!klazz->supports_settings) {
                return FALSE;
        }
        return klazz->supports_settings(self);
}


/**
 * budgie_applet_get_settings_ui:
 *
 * Returns: (transfer full) (nullable): A GTK Settings UI
 */
GtkWidget *budgie_applet_get_settings_ui(BudgieApplet *self)
{
        BudgieAppletClass *klazz = NULL;

        if (!BUDGIE_IS_APPLET(self)) {
                return NULL;
        }

        klazz = BUDGIE_APPLET_GET_CLASS(self);
        if (!klazz->get_settings_ui) {
                return NULL;
        }
        return klazz->get_settings_ui(self);
}

/**
 * budgie_applet_get_applet_settings:
 * @uuid: UUID for this instance
 *
 * Returns: (transfer full): A newly created #GSettings for this applet instance
 */
GSettings *budgie_applet_get_applet_settings(BudgieApplet *self, gchar *uuid)
{
        GSettings *settings = NULL;
        gchar *path = NULL;

        if (!self->priv->schema || !self->priv->prefix) {
                return NULL;
        }

        path = g_strdup_printf("%s/{%s}/", self->priv->prefix, uuid);
        if (!path) {
                return NULL;
        }

        settings = g_settings_new_with_path(self->priv->schema, path);
        g_free(path);
        return settings;
}

static void budgie_applet_dispose(GObject *g_object)
{
        BudgieApplet *self = BUDGIE_APPLET(g_object);

        FREE_IF_SET(prefix);
        FREE_IF_SET(schema);

        G_OBJECT_CLASS(budgie_applet_parent_class)->dispose(g_object);
}

static void budgie_applet_class_init(BudgieAppletClass *klazz)
{
        GObjectClass *obj_class = G_OBJECT_CLASS(klazz);

        obj_class->get_property = budgie_applet_get_property;
        obj_class->set_property = budgie_applet_set_property;
        obj_class->dispose = budgie_applet_dispose;

        klazz->update_popovers = NULL;

        /* Todo, make the PREFIX/SCHEMA G_PARAM_CONSTRUCT_ONLY */

        /**
         * BudgieApplet::settings-prefix:
         *
         * The GSettinges schema path prefix for this applet
         */
        obj_properties[PROP_PREFIX] = g_param_spec_string("settings-prefix",
                "GSettings schema prefix", "Set the GSettings schema prefix",
                NULL, G_PARAM_READWRITE);

        /**
         * BudgieApplet::settings-schema:
         *
         * The ID of the GSettings schema used by this applet
         */
        obj_properties[PROP_SCHEMA] = g_param_spec_string("settings-schema",
                "GSettings relocatable schema ID", "Set the GSettings relocatable schema ID",
                NULL, G_PARAM_READWRITE);

        /*
         * BudgieApplet::supported-actions:
         *
         * The actions supported by this applet instance
         */
        obj_properties[PROP_ACTIONS] = g_param_spec_flags("supported-actions",
                "Supported panel actions", "Get/set the supported panel actions",
                BUDGIE_TYPE_PANEL_ACTION, BUDGIE_PANEL_ACTION_NONE, G_PARAM_READWRITE);

        /**
         * BudgieApplet::panel-size-changed:
         * @applet: The applet recieving the signal
         * @panel_size: The new panel size
         * @icon_size: Larget possible icon size for the panel
         * @small_icon_size: Smaller icon that will still fit on the panel
         *
         * Used to notify this applet of a change in the panel size
         */
        applet_signals[POSITION_CHANGED] = g_signal_new("panel-size-changed", BUDGIE_TYPE_APPLET,
                G_SIGNAL_RUN_LAST|G_SIGNAL_ACTION,
                G_STRUCT_OFFSET(BudgieAppletClass, panel_size_changed),
                NULL, NULL, NULL,
                G_TYPE_NONE,
                3,
                G_TYPE_INT, G_TYPE_INT, G_TYPE_INT);


        g_object_class_install_properties(obj_class, N_PROPS, obj_properties);

}

void budgie_applet_set_settings_prefix(BudgieApplet *self, const gchar *prefix)
{
        if (!self || !prefix) {
                return;
        }

        BudgieAppletPrivate *priv = self->priv;
        if (priv->prefix) {
                g_free(priv->prefix);
        }
        priv->prefix = g_strdup(prefix);
}

const gchar *budgie_applet_get_settings_prefix(BudgieApplet *self)
{
        if (!self) {
                return NULL;
        }
        return (const gchar*)self->priv->prefix;
}

void budgie_applet_set_settings_schema(BudgieApplet *self, const gchar *schema)
{
        if (!self || !schema) {
                return;
        }

        BudgieAppletPrivate *priv = self->priv;;
        if (priv->schema) {
                g_free(priv->schema);
        }
        priv->schema = g_strdup(schema);
}

const gchar *budgie_applet_get_settings_schema(BudgieApplet *self)
{
        if (!self) {
                return NULL;
        }
        return (const gchar*)self->priv->schema;
}

/**
 * budgie_applet_update_popovers:
 * @manager: (nullable)
 */
void budgie_applet_update_popovers(BudgieApplet *self, BudgiePopoverManager *manager)
{
        if (!self) {
                return;
        }
        BudgieAppletClass *klazz = BUDGIE_APPLET_GET_CLASS(self);

        if (klazz->update_popovers) {
                klazz->update_popovers(self, manager);
        }
}
        
BudgiePanelAction budgie_applet_get_supported_actions(BudgieApplet *self)
{
        if (!self) {
                return BUDGIE_PANEL_ACTION_NONE;
        }
        return self->priv->actions;
}

static void budgie_applet_init(BudgieApplet *self)
{
        self->priv = budgie_applet_get_instance_private(self);
}

/**
 * budgie_applet_new:
 *
 * Returns: (transfer full): A new BudgieApplet
 */
BudgieApplet *budgie_applet_new()
{
        return g_object_new(BUDGIE_TYPE_APPLET, NULL);
}
