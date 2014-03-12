/*
 * windowlist-applet.h
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
#ifndef windowlist_applet_h
#define windowlist_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

#include "panel-applet.h"

typedef struct _WindowlistApplet WindowlistApplet;
typedef struct _WindowlistAppletClass   WindowlistAppletClass;

#define WINDOWLIST_APPLET_TYPE (windowlist_applet_get_type())
#define WINDOWLIST_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), WINDOWLIST_APPLET_TYPE, WindowlistApplet))
#define IS_WINDOWLIST_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), WINDOWLIST_APPLET_TYPE))
#define WINDOWLIST_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), WINDOWLIST_APPLET_TYPE, WindowlistAppletClass))
#define IS_WINDOWLIST_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), WINDOWLIST_APPLET_TYPE))
#define WINDOWLIST_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), WINDOWLIST_APPLET_TYPE, WindowlistAppletClass))

/* WindowlistApplet object */
struct _WindowlistApplet {
        PanelApplet parent;
};

/* WindowlistApplet class definition */
struct _WindowlistAppletClass {
        PanelAppletClass parent_class;
};

GType windowlist_applet_get_type(void);

/* WindowlistApplet methods */

/**
 * Construct a new WindowlistApplet
 * @return A new WindowlistApplet
 */
GtkWidget *windowlist_applet_new(void);

#endif /* windowlist_applet_h */
