/*
 * windowlist-applet.c
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <libwnck/libwnck.h>

#include "windowlist-applet.h"
#include "icon-tasklist.h"

G_DEFINE_TYPE(WindowlistApplet, windowlist_applet, PANEL_APPLET_TYPE)

/* Boilerplate GObject code */
static void windowlist_applet_class_init(WindowlistAppletClass *klass);
static void windowlist_applet_init(WindowlistApplet *self);
static void windowlist_applet_dispose(GObject *object);

/* Initialisation */
static void windowlist_applet_class_init(WindowlistAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &windowlist_applet_dispose;
}

static void windowlist_applet_init(WindowlistApplet *self)
{
        GtkWidget *tasklist;

        /*tasklist = wnck_tasklist_new();
        wnck_tasklist_set_button_relief(WNCK_TASKLIST(tasklist),
                GTK_RELIEF_NONE);*/
        tasklist = icon_tasklist_new();
        gtk_container_add(GTK_CONTAINER(self), tasklist);
}

static void windowlist_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (windowlist_applet_parent_class)->dispose (object);
}

/* Utility; return a new WindowlistApplet */
GtkWidget *windowlist_applet_new(void)
{
        WindowlistApplet *self;

        self = g_object_new(WINDOWLIST_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}
