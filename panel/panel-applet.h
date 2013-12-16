/*
 * panel-applet.h
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
#ifndef panel_applet_h
#define panel_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

typedef struct _PanelApplet PanelApplet;
typedef struct _PanelAppletClass   PanelAppletClass;

#define PANEL_APPLET_TYPE (panel_applet_get_type())
#define PANEL_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), PANEL_APPLET_TYPE, PanelApplet))
#define IS_PANEL_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), PANEL_APPLET_TYPE))
#define PANEL_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), PANEL_APPLET_TYPE, PanelAppletClass))
#define IS_PANEL_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), PANEL_APPLET_TYPE))
#define PANEL_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), PANEL_APPLET_TYPE, PanelAppletClass))

/* PanelApplet object */
struct _PanelApplet {
        GtkBin parent;
};

/* PanelApplet class definition */
struct _PanelAppletClass {
        GtkBinClass parent_class;
};

GType panel_applet_get_type(void);

/* PanelApplet methods */

/**
 * Construct a new PanelApplet
 * @return A new PanelApplet
 */
GtkWidget* panel_applet_new(void);

#endif /* panel_applet_h */
