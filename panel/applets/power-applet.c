/*
 * budgie-panel.c
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

#include "power-applet.h"

G_DEFINE_TYPE(PowerApplet, power_applet, GTK_TYPE_BIN)

/* Boilerplate GObject code */
static void power_applet_class_init(PowerAppletClass *klass);
static void power_applet_init(PowerApplet *self);
static void power_applet_dispose(GObject *object);


/* Initialisation */
static void power_applet_class_init(PowerAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &power_applet_dispose;
}

static void power_applet_init(PowerApplet *self)
{
        GtkWidget *image;

        image = gtk_image_new();
        self->image = image;
        gtk_container_add(GTK_CONTAINER(self), image);

        gtk_image_set_from_icon_name(GTK_IMAGE(image),
                "battery-good-symbolic", GTK_ICON_SIZE_BUTTON);

        gtk_container_set_border_width(GTK_CONTAINER(self), 5);
}

static void power_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (power_applet_parent_class)->dispose (object);
}

/* Utility; return a new PowerApplet */
GtkWidget* power_applet_new(void)
{
        PowerApplet *self;

        self = g_object_new(POWER_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}
