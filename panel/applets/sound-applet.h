/*
 * sound-applet.h
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
#ifndef sound_applet_h
#define sound_applet_h

#include <glib-object.h>
#include <gtk/gtk.h>

#include "../panel-applet.h"
#include <pulse/pulseaudio.h>
#include "gvc-mixer-control.h"

typedef struct _SoundApplet SoundApplet;
typedef struct _SoundAppletClass   SoundAppletClass;

#define SOUND_APPLET_TYPE (sound_applet_get_type())
#define SOUND_APPLET(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), SOUND_APPLET_TYPE, SoundApplet))
#define IS_SOUND_APPLET(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), SOUND_APPLET_TYPE))
#define SOUND_APPLET_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), SOUND_APPLET_TYPE, SoundAppletClass))
#define IS_SOUND_APPLET_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), SOUND_APPLET_TYPE))
#define SOUND_APPLET_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), SOUND_APPLET_TYPE, SoundAppletClass))

/* SoundApplet object */
struct _SoundApplet {
        PanelApplet parent;
        GtkWidget *label;
};

/* SoundApplet class definition */
struct _SoundAppletClass {
        PanelAppletClass parent_class;
};

GType sound_applet_get_type(void);

/* SoundApplet methods */

/**
 * Construct a new SoundApplet
 * @return A new SoundApplet
 */
GtkWidget* sound_applet_new(void);

#endif /* sound_applet_h */
