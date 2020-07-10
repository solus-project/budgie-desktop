/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2020-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#ifndef __CARBON_CHILD_H__
#define __CARBON_CHILD_H__

#include <gtk/gtk.h>
#include <gtk/gtkx.h>
#include <stdbool.h>

typedef struct _CarbonChild {
	GtkSocket parent;

	int preferredWidth;
	int preferredHeight;
	Window iconWindow;

	char *wmclass;

	bool parentRelativeBg;
	bool isComposited;
} CarbonChild;

typedef struct _CarbonChildClass {
	GtkSocketClass parent_class;
} CarbonChildClass;



#define CARBON_TYPE_CHILD (carbon_child_get_type())
#define CARBON_CHILD(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), CARBON_TYPE_CHILD, CarbonChild))
#define CARBON_IS_CHILD(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CARBON_TYPE_CHILD))



GType carbon_child_get_type(void);

CarbonChild* carbon_child_new(int, GdkScreen*, Window);

void carbon_child_draw_on_tray(CarbonChild*, GtkWidget*, cairo_t*);

#endif
