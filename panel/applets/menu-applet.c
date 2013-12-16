/*
 * menu-applet.c
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

#include "menu-applet.h"
#include "menu-window.h"

G_DEFINE_TYPE(MenuApplet, menu_applet, PANEL_APPLET_TYPE)

/* Boilerplate GObject code */
static void menu_applet_class_init(MenuAppletClass *klass);
static void menu_applet_init(MenuApplet *self);
static void menu_applet_dispose(GObject *object);

static gboolean focus_out_cb(GtkWidget *widget, GdkEvent *event,
                             gpointer userdata);
static gboolean key_release_cb(GtkWidget *widget, GdkEventKey *event,
                               gpointer userdata);
static void toggled_cb(GtkWidget *widget, gpointer userdata);

/* Initialisation */
static void menu_applet_class_init(MenuAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &menu_applet_dispose;
}

static void menu_applet_init(MenuApplet *self)
{
        GtkWidget *menu, *menu_label, *menu_box, *menu_image;
        GtkWidget *menu_window;

        menu = gtk_toggle_button_new();
        gtk_container_add(GTK_CONTAINER(self), menu);
        self->menu_button = menu;
        self->toggle_id = g_signal_connect(menu, "toggled",
                G_CALLBACK(toggled_cb), (gpointer)self);
        gtk_button_set_relief(GTK_BUTTON(menu), GTK_RELIEF_NONE);
        gtk_widget_set_can_focus(menu, FALSE);
        g_object_set(menu, "margin-left", 3, "margin-right", 15, NULL);

        /* Add content to menu button. */
        menu_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_container_add(GTK_CONTAINER(menu), menu_box);
        menu_image = gtk_image_new_from_icon_name("start-here",
                GTK_ICON_SIZE_MENU);
        gtk_box_pack_start(GTK_BOX(menu_box), menu_image, FALSE, FALSE, 0);
        g_object_set(menu_image, "margin-right", 8, NULL);
        menu_label = gtk_label_new("Menu");
        gtk_box_pack_start(GTK_BOX(menu_box), menu_label, TRUE, TRUE, 0);

        /* Pretty popup menu */
        menu_window = menu_window_new();
        g_signal_connect(menu_window, "focus-out-event",
                G_CALLBACK(focus_out_cb), (gpointer)self);
        g_signal_connect(menu_window, "key-release-event",
                G_CALLBACK(key_release_cb), (gpointer)self);
        self->menu_window = menu_window;
}

static void menu_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (menu_applet_parent_class)->dispose (object);
}

/* Utility; return a new MenuApplet */
GtkWidget* menu_applet_new(void)
{
        MenuApplet *self;

        self = g_object_new(MENU_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}

static gboolean focus_out_cb(GtkWidget *widget, GdkEvent *event,
                             gpointer userdata)
{
        MenuApplet *self;

        self = MENU_APPLET(userdata);
        g_signal_handler_block(self->menu_button, self->toggle_id);
        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(self->menu_button),
                FALSE);
        g_signal_handler_unblock(self->menu_button, self->toggle_id);

        gtk_widget_hide(self->menu_window);
        return TRUE;
}

static gboolean key_release_cb(GtkWidget *widget, GdkEventKey *event,
                               gpointer userdata)
{
        if (event->keyval != GDK_KEY_Escape)
                return FALSE;
        return focus_out_cb(widget, NULL, userdata);
}

static void toggled_cb(GtkWidget *widget, gpointer userdata)
{
        MenuApplet *self;
        GtkToggleButton *button;
        GdkScreen *screen;
        int y;
        GtkAllocation alloc;

        self = MENU_APPLET(userdata);
        button = GTK_TOGGLE_BUTTON(widget);
        if (!gtk_toggle_button_get_active(button)) {
                gtk_widget_hide(self->menu_window);
                return;
        }

        /* Place it near our menu button */
        screen = gtk_widget_get_screen(widget);
        gtk_widget_get_allocation(GTK_WIDGET(self), &alloc);
        y = gdk_screen_get_height(screen) - alloc.height;
        gtk_window_move(GTK_WINDOW(self->menu_window), 0, y);
        menu_window_present(MENU_WINDOW(self->menu_window));
        gtk_widget_show_all(self->menu_window);
}
