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

/* Private methods */
static void update_ui(PowerApplet *self);
static void device_changed_cb(UpClient *client,
                             UpDevice *device,
                             gpointer userdata);

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

        /* Display battery status using an image */
        image = gtk_image_new();
        self->image = image;
        gtk_container_add(GTK_CONTAINER(self), image);

        gtk_container_set_border_width(GTK_CONTAINER(self), 5);

        /* Initialise upower */
        self->client = up_client_new();
        g_signal_connect(self->client, "device-changed",
                G_CALLBACK(device_changed_cb), (gpointer)self);
        self->battery = NULL;
        update_ui(self);
}

static void power_applet_dispose(GObject *object)
{
        PowerApplet *self;

        self = POWER_APPLET(object);
        if (self->battery) {
                g_object_unref(self->battery);
                self->battery = NULL;
        }
        if (self->client) {
                g_object_unref(self->client);
                self->client = NULL;
        }
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

static void update_ui(PowerApplet *self)
{
        GPtrArray *devices = NULL;
        GError *error = NULL;
        UpDeviceKind kind;
        UpDevice *device;
        int i;
        gdouble percent;
        gchar *image_name = NULL, *image = NULL;
        guint8 state;
        /* No .0000's */
        gint percent2;
        gchar *tooltip = NULL;

        if (!self->battery) {
                /* Determine the battery device */
                up_client_enumerate_devices_sync(self->client, NULL, &error);
                if (error) {
                        g_warning("Unable to list devices: %s",
                                error->message);
                        goto end;
                }
                devices = up_client_get_devices(self->client);
                for (i = 0; i < devices->len; i++) {
                        device = (UpDevice*)devices->pdata[i];
                        g_object_get(device, "kind", &kind, NULL);
                        if (kind == UP_DEVICE_KIND_BATTERY) {
                                /* Store a reference to this */
                                self->battery = device;
                                device = NULL;
                                g_object_ref(self->battery);
                                break;
                        }
                }
                if (!self->battery) {
                        g_warning("Unable to discover a battery");
                        goto end;
                }
        }
        /* Got a battery, query the percent */
        g_object_get(self->battery, "percentage", &percent, NULL);
        g_object_get(self->battery, "state", &state, NULL);

        /* "empty" "low" "good" "full" */
        if (percent <= 10)
                image_name = "battery-empty";
        else if (percent <= 35)
                image_name = "battery-low";
        else if (percent <= 99)
                image_name = "battery-good";
        else
                image_name = "battery-full";
        /* Fully charged OR charging */
        if (state == 4)
                image_name = "battery-full-charged";
        else if (state == 1)
                image = g_strdup_printf("%s-charging-symbolic", image_name);
        else
                image = g_strdup_printf("%s-symbolic", image_name);

        /* Set a helpful tooltip */
        percent2 = (gint)percent;
        tooltip = g_strdup_printf("Battery remaining: %d%%", percent2);
        gtk_widget_set_tooltip_text(GTK_WIDGET(self), tooltip);
        g_free(tooltip);

        gtk_image_set_from_icon_name(GTK_IMAGE(self->image), image,
                GTK_ICON_SIZE_BUTTON);
        g_free(image);

end:
        if (error)
                g_error_free(error);
        if (devices)
                g_ptr_array_unref(devices);
}

static void device_changed_cb(UpClient *client,
                             UpDevice *device,
                             gpointer userdata)
{
        PowerApplet *self;

        self = POWER_APPLET(userdata);
        if (device == self->battery)
                update_ui(self);
}
