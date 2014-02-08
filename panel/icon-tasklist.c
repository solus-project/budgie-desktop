/*
 * icon-tasklist.c
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
#include "icon-tasklist.h"

/* IconTasklist object */
struct _IconTasklist {
        GtkBox parent;
};

/* IconTasklist class definition */
struct _IconTasklistClass {
        GtkBoxClass parent_class;
};

G_DEFINE_TYPE(IconTasklist, icon_tasklist, GTK_TYPE_BOX)

/* Boilerplate GObject code */
static void icon_tasklist_class_init(IconTasklistClass *klass);
static void icon_tasklist_init(IconTasklist *self);
static void icon_tasklist_dispose(GObject *object);

/* Initialisation */
static void icon_tasklist_class_init(IconTasklistClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &icon_tasklist_dispose;
}

static void icon_tasklist_init(IconTasklist *self)
{
}

static void icon_tasklist_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (icon_tasklist_parent_class)->dispose (object);
}

/* Utility; return a new IconTasklist */
GtkWidget *icon_tasklist_new(void)
{
        IconTasklist *self;

        self = g_object_new(ICON_TASKLIST_TYPE, NULL);
        return GTK_WIDGET(self);
}
