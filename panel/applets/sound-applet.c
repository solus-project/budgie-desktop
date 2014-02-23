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
#include <math.h>

G_DEFINE_TYPE(SoundApplet, sound_applet, PANEL_APPLET_TYPE)

/* Boilerplate GObject code */
static void sound_applet_class_init(SoundAppletClass *klass);
static void sound_applet_init(SoundApplet *self);
static void sound_applet_dispose(GObject *object);

static void update_volume(SoundApplet *self);
static void state_changed(GvcMixerControl *mix, guint status, gpointer userdata);


/* Initialisation */
static void sound_applet_class_init(SoundAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &sound_applet_dispose;
}

static void update_volume(SoundApplet *self)
{
        GvcMixerStream *stream;
        gdouble vol_norm;
        pa_volume_t vol;
        int n;
        const gchar *image;
        gdouble db;
        gchar *tooltip = NULL;

        stream = gvc_mixer_control_get_default_sink(self->mixer);
        vol_norm = gvc_mixer_control_get_vol_max_norm(self->mixer);
        vol = gvc_mixer_stream_get_volume(stream);

        /* Same maths as computed by volume.js in gnome-shell */
        n = floor(3*vol/vol_norm);

        if (gvc_mixer_stream_get_is_muted(stream)) {
                image = "audio-volume-muted-symbolic";
        } else {
                switch (n) {
                        case 3:
                                image = "audio-volume-high-symbolic";
                                break;
                        case 2:
                                image = "audio-volume-medium-symbolic";
                                break;
                        default:
                                image = "audio-volume-low-symbolic";
                                break;
                }
        }
        gtk_image_set_from_icon_name(GTK_IMAGE(self->image),
                image, GTK_ICON_SIZE_BUTTON);

        /* Now update the tooltip with dB level */
        if (gvc_mixer_stream_get_can_decibel(stream)) {
                db = gvc_mixer_stream_get_decibel(stream);
                tooltip = g_strdup_printf("%f dB", db);
                gtk_widget_set_tooltip_text(GTK_WIDGET(self), tooltip);
                g_free(tooltip);
        }
}
static void state_changed(GvcMixerControl *mix, guint status, gpointer userdata)
{
        /* First time we connect, update the volume */
        if (status == GVC_STATE_READY) {
                update_volume(SOUND_APPLET(userdata));
        }
}

static void sound_applet_init(SoundApplet *self)
{
        GvcMixerControl *mixer;
        GtkWidget *image;

        mixer = gvc_mixer_control_new(MIXER_NAME);
        g_signal_connect(mixer, "state-changed", G_CALLBACK(state_changed), self);
        gvc_mixer_control_open(mixer);
        self->mixer = mixer;

        image = gtk_image_new();
        self->image = image;
        gtk_container_add(GTK_CONTAINER(self), image);
}

static void sound_applet_dispose(GObject *object)
{
        SoundApplet *self;

        self = SOUND_APPLET(object);
        if (self->mixer) {
                gvc_mixer_control_close(self->mixer);
                g_object_unref(self->mixer);
                self->mixer = NULL;
        }
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
