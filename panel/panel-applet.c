/*
 * panel-applet.c
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "panel-applet.h"

G_DEFINE_TYPE(PanelApplet, panel_applet, GTK_TYPE_BIN)

/* Boilerplate GObject code */
static void panel_applet_class_init(PanelAppletClass *klass);
static void panel_applet_init(PanelApplet *self);
static void panel_applet_dispose(GObject *object);

/* Initialisation */
static void panel_applet_class_init(PanelAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &panel_applet_dispose;
}

static void panel_applet_init(PanelApplet *self)
{
}

static void panel_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (panel_applet_parent_class)->dispose (object);
}

/* Utility; return a new PanelApplet */
GtkWidget *panel_applet_new(void)
{
        PanelApplet *self;

        self = g_object_new(PANEL_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}
