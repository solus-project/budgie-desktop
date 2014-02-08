/*
 * clock-applet.c
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

#include "clock-applet.h"

G_DEFINE_TYPE(ClockApplet, clock_applet, PANEL_APPLET_TYPE)

static gboolean update_clock(gpointer userdata);

/* Boilerplate GObject code */
static void clock_applet_class_init(ClockAppletClass *klass);
static void clock_applet_init(ClockApplet *self);
static void clock_applet_dispose(GObject *object);

/* Initialisation */
static void clock_applet_class_init(ClockAppletClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &clock_applet_dispose;
}

static void clock_applet_init(ClockApplet *self)
{
        self->label = gtk_label_new("--");
        gtk_container_add(GTK_CONTAINER(self), self->label);

        /* Don't show an empty label */
        update_clock(self);
        /* Update the clock every second */
        g_timeout_add(1000, update_clock, self);
}

static void clock_applet_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (clock_applet_parent_class)->dispose (object);
}

/* Utility; return a new ClockApplet */
GtkWidget* clock_applet_new(void)
{
        ClockApplet *self;

        self = g_object_new(CLOCK_APPLET_TYPE, NULL);
        return GTK_WIDGET(self);
}

static gboolean update_clock(gpointer userdata)
{
        ClockApplet *self;
        gchar *date_string;
        GDateTime *dtime;
        /* TODO: Make configurable */
        gboolean show_date = FALSE;

        self = CLOCK_APPLET(userdata);

        /* Get the current time */
        dtime = g_date_time_new_now_local();

        if (show_date)
                date_string = g_date_time_format(dtime,
                        " <big>%H:%M:%S</big> <small>%x</small> ");
        else
                date_string = g_date_time_format(dtime,
                        " <big>%H:%M:%S</big> ");

        gtk_label_set_markup(GTK_LABEL(self->label), date_string);
        g_free(date_string);
        g_date_time_unref(dtime);

        return TRUE;
}
