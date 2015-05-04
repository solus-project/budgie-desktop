/*
 * windowmenu.h
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 */
#pragma once

#include <glib-object.h>
#include <gtk/gtk.h>

typedef struct _BudgieWindowMenu BudgieWindowMenu;
typedef struct _BudgieWindowMenuClass   BudgieWindowMenuClass;
typedef struct _BudgieWindowMenuPrivate BudgieWindowMenuPrivate;

#define BUDGIE_WINDOW_MENU_TYPE (budgie_window_menu_get_type())
#define BUDGIE_WINDOW_MENU(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_WINDOW_MENU_TYPE, BudgieWindowMenu))
#define IS_BUDGIE_WINDOW_MENU(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_WINDOW_MENU_TYPE))
#define BUDGIE_WINDOW_MENU_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_WINDOW_MENU_TYPE, BudgieWindowMenuClass))
#define IS_BUDGIE_WINDOW_MENU_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_WINDOW_MENU_TYPE))
#define BUDGIE_WINDOW_MENU_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_WINDOW_MENU_TYPE, BudgieWindowMenuClass))

/* BudgieWindowMenu object */
struct _BudgieWindowMenu {
        GtkMenu parent;
        BudgieWindowMenuPrivate* priv;
};

/* BudgieWindowMenu class definition */
struct _BudgieWindowMenuClass {
        GtkMenuClass parent_class;
};

GType budgie_window_menu_get_type(void);

/* BudgieWindowMenu methods */

/**
 * Construct a new BudgieWindowMenu
 * @return A new BudgieWindowMenu
 */
GtkWidget *budgie_window_menu_new(void);
