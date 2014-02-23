/*
 * clock-applet.h
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
#ifndef clock_applet_h
#define clock_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

#include "panel-applet.h"

typedef struct _ClockApplet ClockApplet;
typedef struct _ClockAppletClass   ClockAppletClass;

#define CLOCK_APPLET_TYPE (clock_applet_get_type())
#define CLOCK_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CLOCK_APPLET_TYPE, ClockApplet))
#define IS_CLOCK_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CLOCK_APPLET_TYPE))
#define CLOCK_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), CLOCK_APPLET_TYPE, ClockAppletClass))
#define IS_CLOCK_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), CLOCK_APPLET_TYPE))
#define CLOCK_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), CLOCK_APPLET_TYPE, ClockAppletClass))

/* ClockApplet object */
struct _ClockApplet {
        PanelApplet parent;
        GtkWidget *label;
};

/* ClockApplet class definition */
struct _ClockAppletClass {
        PanelAppletClass parent_class;
};

GType clock_applet_get_type(void);

/* ClockApplet methods */

/**
 * Construct a new ClockApplet
 * @return A new ClockApplet
 */
GtkWidget* clock_applet_new(void);

#endif /* clock_applet_h */
