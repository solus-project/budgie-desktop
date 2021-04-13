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

#include <glib-object.h>
#include <gtk/gtk.h>
#include <libpeas/peas.h>

#include "applet-info.h"
#include "applet.h"

G_BEGIN_DECLS

typedef struct _BudgieAppletInfoPrivate BudgieAppletInfoPrivate;
typedef struct _BudgieAppletInfo BudgieAppletInfo;
typedef struct _BudgieAppletInfoClass BudgieAppletInfoClass;

#define BUDGIE_TYPE_APPLET_INFO budgie_applet_info_get_type()
#define BUDGIE_APPLET_INFO(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_APPLET_INFO, BudgieAppletInfo))
#define BUDGIE_IS_APPLET_INFO(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_APPLET_INFO))
#define BUDGIE_APPLET_INFO_CLASS(o) (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_APPLET_INFO, BudgieAppletInfoClass))
#define BUDGIE_IS_APPLET_INFO_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_APPLET_INFO))
#define BUDGIE_APPLET_INFO_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_APPLET_INFO, BudgieAppletInfoClass))

/**
 * BudgieAppletInfoClass
 */
struct _BudgieAppletInfoClass {
	GObjectClass parent_class;
};

/**
 * BudgieAppletInfo:
 *
 * This type is private to the panel implementation, and is used to monitor, track,
 * and control each applet instance.
 */
struct _BudgieAppletInfo {
	GObject parent_instance;
	BudgieAppletInfoPrivate* priv;
};

BudgieAppletInfo* budgie_applet_info_new_from_uuid(const char* uuid);

BudgieAppletInfo* budgie_applet_info_new(PeasPluginInfo* plugin_info, const char* uuid, BudgieApplet* applet, GSettings* settings);

GType budgie_applet_info_get_type(void);

G_END_DECLS
