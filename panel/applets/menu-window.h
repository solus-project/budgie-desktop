/*
 * menu-window.h
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
#ifndef menu_window_h
#define menu_window_h

#include <glib-object.h>
#include <gtk/gtk.h>
#include "budgie-popover.h"

typedef struct _MenuWindow MenuWindow;
typedef struct _MenuWindowClass   MenuWindowClass;
typedef struct _MenuWindowPriv MenuWindowPrivate;

#define MENU_WINDOW_TYPE (menu_window_get_type())
#define MENU_WINDOW(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), MENU_WINDOW_TYPE, MenuWindow))
#define IS_MENU_WINDOW(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), MENU_WINDOW_TYPE))
#define MENU_WINDOW_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), MENU_WINDOW_TYPE, MenuWindowClass))
#define IS_MENU_WINDOW_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), MENU_WINDOW_TYPE))
#define MENU_WINDOW_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), MENU_WINDOW_TYPE, MenuWindowClass))

/* MenuWindow object */
struct _MenuWindow {
        BudgiePopover parent;
        MenuWindowPrivate *priv;
};

/* MenuWindow class definition */
struct _MenuWindowClass {
        BudgiePopoverClass parent_class;
};

GType menu_window_get_type(void);

/* MenuWindow methods */

/**
 * Construct a new MenuWindow
 * @return A new MenuWindow
 */
GtkWidget *menu_window_new(void);

/**
 * Make the window presentable to be visible
 */
void menu_window_present(MenuWindow *self);

#endif /* menu_window_h */
