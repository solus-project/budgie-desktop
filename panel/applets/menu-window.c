/*
 * menu-window.c - Provides a SolusOS-style menu
 *
 * Heavily based on designs and ideas from previous SolusOS iterations
 * and the Cardapio Menu design.
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

#include "menu-window.h"

G_DEFINE_TYPE(MenuWindow, menu_window, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void menu_window_class_init(MenuWindowClass *klass);
static void menu_window_init(MenuWindow *self);
static void menu_window_dispose(GObject *object);

/* Initialisation */
static void menu_window_class_init(MenuWindowClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &menu_window_dispose;
}

static void menu_window_init(MenuWindow *self)
{
}

static void menu_window_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (menu_window_parent_class)->dispose (object);
}

/* Utility; return a new MenuWindow */
GtkWidget* menu_window_new(void)
{
        MenuWindow *self;

        self = g_object_new(MENU_WINDOW_TYPE, NULL);
        return GTK_WIDGET(self);
}
