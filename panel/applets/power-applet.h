/*
 * power-applet.h
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
#ifndef power_applet_h
#define power_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

typedef struct _PowerApplet PowerApplet;
typedef struct _PowerAppletClass   PowerAppletClass;

#define POWER_APPLET_TYPE (power_applet_get_type())
#define POWER_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), POWER_APPLET_TYPE, PowerApplet))
#define IS_POWER_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), POWER_APPLET_TYPE))
#define POWER_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), POWER_APPLET_TYPE, PowerAppletClass))
#define IS_POWER_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), POWER_APPLET_TYPE))
#define POWER_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), POWER_APPLET_TYPE, PowerAppletClass))

/* PowerApplet object */
struct _PowerApplet {
        GtkBin parent;
        GtkWidget *image;
};

/* PowerApplet class definition */
struct _PowerAppletClass {
        GtkBinClass parent_class;
};

GType power_applet_get_type(void);

/* PowerApplet methods */

/**
 * Construct a new PowerApplet
 * @return A new PowerApplet
 */
GtkWidget* power_applet_new(void);

#endif /* power_applet_h */
