/*
 * icon-tasklist.h
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
#ifndef icon_tasklist_h
#define icon_tasklist_h

#include <glib-object.h>
#include <gtk/gtk.h>

typedef struct _IconTasklist IconTasklist;
typedef struct _IconTasklistClass   IconTasklistClass;

#define ICON_TASKLIST_TYPE (icon_tasklist_get_type())
#define ICON_TASKLIST(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), ICON_TASKLIST_TYPE, IconTasklist))
#define IS_ICON_TASKLIST(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), ICON_TASKLIST_TYPE))
#define ICON_TASKLIST_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), ICON_TASKLIST_TYPE, IconTasklistClass))
#define IS_ICON_TASKLIST_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), ICON_TASKLIST_TYPE))
#define ICON_TASKLIST_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), ICON_TASKLIST_TYPE, IconTasklistClass))

GType icon_tasklist_get_type(void);

/* IconTasklist methods */

/**
 * Construct a new IconTasklist
 * @return A new IconTasklist
 */
GtkWidget *icon_tasklist_new(void);

#endif /* icon_tasklist_h */
