/*
 * menu-applet.h
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
#ifndef menu_applet_h
#define menu_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

#include "panel-applet.h"

typedef struct _MenuApplet MenuApplet;
typedef struct _MenuAppletClass   MenuAppletClass;

#define MENU_APPLET_TYPE (menu_applet_get_type())
#define MENU_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), MENU_APPLET_TYPE, MenuApplet))
#define IS_MENU_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MENU_APPLET_TYPE))
#define MENU_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), MENU_APPLET_TYPE, MenuAppletClass))
#define IS_MENU_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), MENU_APPLET_TYPE))
#define MENU_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), MENU_APPLET_TYPE, MenuAppletClass))

/* MenuApplet object */
struct _MenuApplet {
        PanelApplet parent;
        GtkWidget *menu_window;
        GtkWidget *menu_button;
        gulong toggle_id;
};

/* MenuApplet class definition */
struct _MenuAppletClass {
        PanelAppletClass parent_class;
};

GType menu_applet_get_type(void);

/* MenuApplet methods */

/**
 * Construct a new MenuApplet
 * @return A new MenuApplet
 */
GtkWidget *menu_applet_new(void);

/**
 * Present the menu
 * @param applet MenuApplet instance
 */
void menu_applet_show_menu(MenuApplet *applet);

#endif /* menu_applet_h */
