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
        GtkWidget *scroll, *list, *sep;
        GtkWidget *layout, *box;
        GdkScreen *screen;
        GdkVisual *visual;

        /* Sensible default size */
        gtk_window_set_default_size(GTK_WINDOW(self), 470, 510);
        /* Skip, no decorations, etc */
        gtk_window_set_decorated(GTK_WINDOW(self), FALSE);
        gtk_window_set_skip_taskbar_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_skip_pager_hint(GTK_WINDOW(self), TRUE);

        /* Use an RGBA visual to allow rounded windows, etc. */
        screen = gtk_widget_get_screen(GTK_WIDGET(self));
        visual = gdk_screen_get_rgba_visual(screen);
        gtk_widget_set_visual(GTK_WIDGET(self), visual);

        /* Main layout */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);

        /* Left hand side is just a scroller for categories */
        scroll = gtk_scrolled_window_new(NULL, NULL);
        box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
        self->group_box = box;
        gtk_container_add(GTK_CONTAINER(scroll), box);
        gtk_box_pack_start(GTK_BOX(layout), scroll, FALSE, FALSE, 0);

        /* Visual separation */
        sep = gtk_separator_new(GTK_ORIENTATION_VERTICAL);
        gtk_box_pack_start(GTK_BOX(layout), sep, FALSE, FALSE, 0);

        /* Right hand side is similar, just applications */
        scroll = gtk_scrolled_window_new(NULL, NULL);
        list = gtk_list_box_new();
        self->app_box = list;
        gtk_container_add(GTK_CONTAINER(scroll), list);
        gtk_box_pack_start(GTK_BOX(layout), scroll, TRUE, TRUE, 0);
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
