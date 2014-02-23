/*
 * sound-applet.c
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
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

#include "sound-applet.h"

G_DEFINE_TYPE(SoundApplet, sound_applet, PANEL_APPLET_TYPE)

/* Boilerplate GObject code */
static void sound_applet_class_init(SoundAppletClass *klass);
static void sound_applet_init(SoundApplet *self);
static void sound_applet_dispose(GObject *object);

/* Initialisation */
static void sound_applet_class_init(SoundAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &sound_applet_dispose;
}

static void sound_applet_init(SoundApplet *self)
{
}

static void sound_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (sound_applet_parent_class)->dispose (object);
}

/* Utility; return a new SoundApplet */
GtkWidget* sound_applet_new(void)
{
        SoundApplet *self;

        self = g_object_new(SOUND_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}
