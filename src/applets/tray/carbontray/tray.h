/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2021 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#ifndef __CARBON_TRAY_H__
#define __CARBON_TRAY_H__

#include "child.h"
#include <X11/Xatom.h>
#include <gtk/gtk.h>
#include <gtk/gtkx.h>
#include <stdbool.h>

typedef struct {
	GObject parent_instance;

	GtkWidget* box;
	int iconSize;
	bool supportsComposite;

	GHashTable* socketTable;
	GtkWidget* invisible;

	GdkAtom selectionAtom;
	Atom opcodeAtom;
	Atom dataAtom;
	GSList* messages;
} CarbonTray;

typedef struct {
	GObjectClass parent_class;

	void (*message_sent)(CarbonTray* tray, CarbonChild* child, char* message, long id, long timeout);
} CarbonTrayClass;

typedef struct {
	char* string;

	long id;
	long length;
	long remainingLength;
	long timeout;

	Window window;
} CarbonMessage;

typedef struct {
	GtkWidget* box;
	cairo_t* cr;
} CarbonDrawData;


#define CARBON_TYPE_TRAY carbon_tray_get_type()
#define CARBON_TRAY(obj) G_TYPE_CHECK_INSTANCE_CAST((obj), CARBON_TYPE_TRAY, CarbonTray)
#define CARBON_IS_TRAY(obj) G_TYPE_CHECK_INSTANCE_TYPE((obj), CARBON_TYPE_TRAY)
#define CARBON_TRAY_CLASS(klass) G_TYPE_CHECK_CLASS_CAST((klass), CARBON_TYPE_TRAY, CarbonTrayClass))


GType carbon_tray_get_type(void);

CarbonTray* carbon_tray_new(GtkOrientation, int, int);

void carbon_tray_add_to_container(CarbonTray*, GtkContainer*);

void carbon_tray_remove_from_container(CarbonTray*, GtkContainer*);

bool carbon_tray_register(CarbonTray*, GdkScreen*);

void carbon_tray_unregister(CarbonTray*);

void carbon_tray_set_spacing(CarbonTray*, int spacing);

void carbon_tray_unref(CarbonTray*);

#endif
