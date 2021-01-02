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

#include "applet-info.h"
#include <libpeas/peas.h>

enum {
	PROP_ICON = 1,
	PROP_NAME,
	PROP_DESCRIPTION,
	PROP_UUID,
	PROP_ALIGNMENT,
	PROP_POSITION,
	PROP_SETTINGS,
	PROP_APPLET,
	N_PROPS
};

struct _BudgieAppletInfoPrivate {
	BudgieApplet* applet;
	GSettings* settings;
	char* icon;
	char* name;
	char* description;
	char* uuid;
	char* alignment;
	int position;
};

static void budgie_applet_info_bind_settings(BudgieAppletInfo* info);
static void budgie_applet_info_unbind_settings(BudgieAppletInfo* info);

G_DEFINE_TYPE_WITH_PRIVATE(BudgieAppletInfo, budgie_applet_info, G_TYPE_OBJECT)

static GParamSpec* obj_properties[N_PROPS] = {NULL};

static void budgie_applet_info_get_property(GObject* object, guint id, GValue* value, GParamSpec* spec) {
	BudgieAppletInfo* self = BUDGIE_APPLET_INFO(object);

	switch (id) {
		case PROP_ICON:
			g_value_set_string((GValue*) value, self->priv->icon);
			break;
		case PROP_NAME:
			g_value_set_string((GValue*) value, self->priv->name);
			break;
		case PROP_DESCRIPTION:
			g_value_set_string((GValue*) value, self->priv->description);
			break;
		case PROP_UUID:
			g_value_set_string((GValue*) value, self->priv->uuid);
			break;
		case PROP_ALIGNMENT:
			g_value_set_string((GValue*) value, self->priv->alignment);
			break;
		case PROP_POSITION:
			g_value_set_int((GValue*) value, self->priv->position);
			break;
		case PROP_SETTINGS:
			g_value_set_pointer((GValue*) value, g_object_ref(self->priv->settings));
			break;
		case PROP_APPLET:
			if (!self->priv->applet) {
				g_value_set_pointer((GValue*) value, NULL);
			} else {
				g_value_set_pointer((GValue*) value, g_object_ref(self->priv->applet));
			}
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

static void budgie_applet_info_set_property(GObject* object, guint id, const GValue* value, GParamSpec* spec) {
	BudgieAppletInfo* self = BUDGIE_APPLET_INFO(object);
	BudgieApplet* applet = NULL;

	switch (id) {
		case PROP_ICON:
			g_clear_pointer(&self->priv->icon, g_free);
			self->priv->icon = g_value_dup_string(value);
			break;
		case PROP_NAME:
			g_clear_pointer(&self->priv->name, g_free);
			self->priv->name = g_value_dup_string(value);
			break;
		case PROP_DESCRIPTION:
			g_clear_pointer(&self->priv->description, g_free);
			self->priv->description = g_value_dup_string(value);
			break;
		case PROP_UUID:
			g_clear_pointer(&self->priv->uuid, g_free);
			self->priv->uuid = g_value_dup_string(value);
			break;
		case PROP_ALIGNMENT:
			g_clear_pointer(&self->priv->alignment, g_free);
			self->priv->alignment = g_value_dup_string(value);
			break;
		case PROP_POSITION:
			self->priv->position = g_value_get_int((GValue*) value);
			break;
		case PROP_SETTINGS:
			if (self->priv->settings) {
				budgie_applet_info_unbind_settings(self);
			}
			GSettings* settings = g_value_get_pointer((GValue*) value);
			if (!settings) {
				break;
			}
			self->priv->settings = g_object_ref(settings);
			budgie_applet_info_bind_settings(self);
			break;
		case PROP_APPLET:
			applet = g_value_get_pointer((GValue*) value);
			if (!applet) {
				break;
			}
			g_clear_object(&self->priv->applet);
			self->priv->applet = g_object_ref(applet);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

static void budgie_applet_info_dispose(GObject* g_object) {
	BudgieAppletInfo* self = BUDGIE_APPLET_INFO(g_object);

	g_clear_pointer(&self->priv->icon, g_free);
	g_clear_pointer(&self->priv->name, g_free);
	g_clear_pointer(&self->priv->description, g_free);
	g_clear_pointer(&self->priv->uuid, g_free);
	g_clear_pointer(&self->priv->alignment, g_free);
	g_clear_object(&self->priv->applet);

	budgie_applet_info_unbind_settings(self);

	G_OBJECT_CLASS(budgie_applet_info_parent_class)->dispose(g_object);
}

static void budgie_applet_info_class_init(BudgieAppletInfoClass* klazz) {
	GObjectClass* obj_class = G_OBJECT_CLASS(klazz);

	obj_class->get_property = budgie_applet_info_get_property;
	obj_class->set_property = budgie_applet_info_set_property;
	obj_class->dispose = budgie_applet_info_dispose;

	obj_properties[PROP_ICON] = g_param_spec_string(
		"icon", "Applet icon", "Set the applet icon",
		NULL, G_PARAM_READWRITE);

	obj_properties[PROP_NAME] = g_param_spec_string(
		"name", "Applet name", "Set the applet name",
		NULL, G_PARAM_READWRITE);

	obj_properties[PROP_DESCRIPTION] = g_param_spec_string(
		"description", "Applet description", "Set the applet description",
		NULL, G_PARAM_READWRITE);

	obj_properties[PROP_UUID] = g_param_spec_string(
		"uuid", "Applet UUID", "Set the applet UUID",
		NULL, G_PARAM_READWRITE);

	obj_properties[PROP_ALIGNMENT] = g_param_spec_string(
		"alignment", "Applet alignment", "Set the applet alignment",
		"start", G_PARAM_READWRITE);

	obj_properties[PROP_POSITION] = g_param_spec_int(
		"position", "Applet position", "Set the applet position",
		-1000, 1000,
		0, G_PARAM_READWRITE);

	/**
	 * BudgieAppletInfo:settings: (type GSettings)
	 */
	obj_properties[PROP_SETTINGS] = g_param_spec_pointer(
		"settings", "Applet Settings", "Set the applet GSettings",
		G_PARAM_READWRITE | G_PARAM_CONSTRUCT);

	/**
	 * BudgieAppletInfo:applet: (type BudgieApplet)
	 */
	obj_properties[PROP_APPLET] = g_param_spec_pointer(
		"applet", "Applet instance", "Set the applet instance",
		G_PARAM_READWRITE | G_PARAM_CONSTRUCT);

	g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

static void budgie_applet_info_bind_settings(BudgieAppletInfo* self) {
	if (!self || !self->priv->settings) {
		return;
	}

	g_settings_bind(self->priv->settings, BUDGIE_APPLET_KEY_NAME, self, "name", G_SETTINGS_BIND_DEFAULT);
	g_settings_bind(self->priv->settings, BUDGIE_APPLET_KEY_POS, self, "position", G_SETTINGS_BIND_DEFAULT);
	g_settings_bind(self->priv->settings, BUDGIE_APPLET_KEY_ALIGN, self, "alignment", G_SETTINGS_BIND_DEFAULT);
}

static void budgie_applet_info_unbind_settings(BudgieAppletInfo* self) {
	if (!self || !self->priv->settings) {
		return;
	}

	g_settings_unbind(self, "name");
	g_settings_unbind(self, "position");
	g_settings_unbind(self, "alignment");
	g_clear_object(&self->priv->settings);
}

static void budgie_applet_info_init(BudgieAppletInfo* self) {
	self->priv = budgie_applet_info_get_instance_private(self);
}

BudgieAppletInfo* budgie_applet_info_new_from_uuid(const char* uuid) {
	return g_object_new(BUDGIE_TYPE_APPLET_INFO, "uuid", uuid, NULL);
}

BudgieAppletInfo* budgie_applet_info_new(PeasPluginInfo* plugin_info, const char* uuid, BudgieApplet* applet, GSettings* settings) {
	if (plugin_info) {
		return g_object_new(
			BUDGIE_TYPE_APPLET_INFO,
			"icon", peas_plugin_info_get_icon_name(plugin_info),
			"name", peas_plugin_info_get_name(plugin_info),
			"description", peas_plugin_info_get_description(plugin_info),
			"uuid", uuid,
			"applet", applet,
			"settings", settings,
			NULL);
	} else {
		return g_object_new(BUDGIE_TYPE_APPLET_INFO, "uuid", uuid, "applet", applet, "settings", settings, NULL);
	}
}
