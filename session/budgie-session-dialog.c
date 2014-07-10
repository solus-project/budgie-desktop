/*
 * budgie-session-dialog.c
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "common.h"
#include "budgie-session-dialog.h"

G_DEFINE_TYPE(BudgieSessionDialog, budgie_session_dialog, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void budgie_session_dialog_class_init(BudgieSessionDialogClass *klass);
static void budgie_session_dialog_init(BudgieSessionDialog *self);
static void budgie_session_dialog_dispose(GObject *object);

static void clicked(GtkWidget *button, gpointer userdata);
static void init_styles(BudgieSessionDialog *self);

typedef enum {
        SD_CHALLENGE,
        SD_YES,
        SD_NO
} SdResponse;

static inline SdResponse get_response(gchar *resp)
{
        if (g_str_equal(resp, "challenge")) {
                return SD_CHALLENGE;
        } else if (g_str_equal(resp, "yes")) {
                return SD_YES;
        } else {
                return SD_NO;
        }
}

/* Initialisation */
static void budgie_session_dialog_class_init(BudgieSessionDialogClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_session_dialog_dispose;
}


static void budgie_session_dialog_init(BudgieSessionDialog *self)
{
        GtkWidget *main_layout, *layout, *button;
        GtkWidget *top;
        GtkWidget *image;
        GtkWidget *label;
        autofree gchar *txt = NULL;
        GError *error = NULL;
        GtkStyleContext *style;
        gboolean can_reboot = FALSE;
        gboolean can_poweroff = FALSE;
        gboolean can_suspend = FALSE;
        gboolean can_systemd = TRUE;
        autofree gchar *result = NULL;
        SdResponse response;

        init_styles(self);

        /* Let's set up some systemd logic eh? */
        self->proxy = sd_login_manager_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                G_DBUS_OBJECT_MANAGER_CLIENT_FLAGS_NONE,
                "org.freedesktop.login1",
                "/org/freedesktop/login1",
                NULL,
                &error);
        if (error) {
                g_error_free(error);
                can_systemd = FALSE;
        } else {
                can_systemd = TRUE;
        }

        if (can_systemd) {
                /* Can we reboot? */
                if (!sd_login_manager_call_can_reboot_sync(self->proxy,
                        &result, NULL, NULL)) {
                        can_reboot = FALSE;
                } else {
                        response = get_response(result);
                        if (response == SD_YES || response == SD_CHALLENGE) {
                                can_reboot = TRUE;
                        }
                        g_free(result);
                        result = NULL;
                }
                /* Can we suspend? */
                if (!sd_login_manager_call_can_suspend_sync(self->proxy,
                        &result, NULL, NULL)) {
                        can_suspend = FALSE;
                } else {
                        response = get_response(result);
                        if (response == SD_YES || response == SD_CHALLENGE) {
                                can_suspend = TRUE;
                        }
                        g_free(result);
                        result = NULL;
                }
                /* Can we shutdown? */
                if (!sd_login_manager_call_can_power_off_sync(self->proxy,
                        &result, NULL, NULL)) {
                        can_poweroff = FALSE;
                } else {
                        response = get_response(result);
                        if (response == SD_YES || response == SD_CHALLENGE) {
                                can_poweroff = TRUE;
                        }
                        g_free(result);
                        result = NULL;
                }
        }

        gtk_window_set_position(GTK_WINDOW(self), GTK_WIN_POS_CENTER_ALWAYS);
        gtk_window_set_skip_taskbar_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_skip_pager_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_title(GTK_WINDOW(self), "End your session?");
        gtk_window_set_default_size(GTK_WINDOW(self), 300, -1);

        main_layout = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
        gtk_container_set_border_width(GTK_CONTAINER(main_layout), 10);
        gtk_container_add(GTK_CONTAINER(self), main_layout);

        top = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_box_pack_start(GTK_BOX(main_layout), top, FALSE, FALSE, 0);

        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_widget_set_halign(layout, GTK_ALIGN_CENTER);
        gtk_box_pack_start(GTK_BOX(main_layout), layout, TRUE, TRUE, 0);

        /* Nice side image.. because why not */
        image = gtk_image_new_from_icon_name("system-shutdown-symbolic",
                GTK_ICON_SIZE_INVALID);
        gtk_image_set_pixel_size(GTK_IMAGE(image), 48);
        gtk_box_pack_start(GTK_BOX(top), image, FALSE, FALSE, 0);

        /* And a helpful label */
        txt = g_strdup_printf("<big>Goodbye, %s!</big>", g_get_user_name());
        label = gtk_label_new(txt);
        gtk_label_set_use_markup(GTK_LABEL(label), TRUE);
        gtk_box_pack_start(GTK_BOX(top), label, TRUE, TRUE, 0);

        /* Add some buttons to uh.. logout, etc. :) */
        button = gtk_button_new_with_label("Logout");
        g_object_set_data(G_OBJECT(button), "action", "logout");
        g_signal_connect(button, "clicked", G_CALLBACK(clicked), self);
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);

        button = gtk_button_new_with_label("Reboot");
        g_object_set_data(G_OBJECT(button), "action", "reboot");
        g_signal_connect(button, "clicked", G_CALLBACK(clicked), self);
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);
        if (!can_reboot) {
                gtk_widget_set_sensitive(GTK_WIDGET(button), FALSE);
        }

        button = gtk_button_new_with_label("Suspend");
        g_object_set_data(G_OBJECT(button), "action", "suspend");
        g_signal_connect(button, "clicked", G_CALLBACK(clicked), self);
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);
        if (!can_suspend) {
                gtk_widget_set_sensitive(GTK_WIDGET(button), FALSE);
        }

        button = gtk_button_new_with_label("Poweroff");
        g_object_set_data(G_OBJECT(button), "action", "poweroff");
        g_signal_connect(button, "clicked", G_CALLBACK(clicked), self);
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);
        if (!can_poweroff) {
                gtk_widget_set_sensitive(GTK_WIDGET(button), FALSE);
        }

        button = gtk_button_new_with_label("Cancel");
        g_object_set_data(G_OBJECT(button), "action", "cancel");
        g_signal_connect(button, "clicked", G_CALLBACK(clicked), self);
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);

        /* Cheat, shadow + styling, but no titlebar */
        gtk_window_set_titlebar(GTK_WINDOW(self), gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0));

        /* Can haz style? */
        style = gtk_widget_get_style_context(GTK_WIDGET(self));
        gtk_style_context_add_class(style, GTK_STYLE_CLASS_OSD);
}

static void budgie_session_dialog_dispose(GObject *object)
{
        BudgieSessionDialog *self;

        self = BUDGIE_SESSION_DIALOG(object);
        if (self->proxy) {
                g_object_unref(self->proxy);
                self->proxy = NULL;
        }
        /* Destruct */
        G_OBJECT_CLASS (budgie_session_dialog_parent_class)->dispose (object);
}

/* Utility; return a new BudgieSessionDialog */
BudgieSessionDialog *budgie_session_dialog_new(void)
{
        BudgieSessionDialog *self;

        self = g_object_new(BUDGIE_SESSION_DIALOG_TYPE, NULL);
        return self;
}

static void clicked(GtkWidget *button, gpointer userdata)
{
        BudgieSessionDialog *self;
        const gchar *data;
        GError *error = NULL;

        self = BUDGIE_SESSION_DIALOG(userdata);
        data = g_object_get_data(G_OBJECT(button), "action");

        if (g_str_equal(data, "poweroff")) {
                /* Poweroff */
                sd_login_manager_call_power_off_sync(self->proxy, TRUE, NULL, &error);
                if (error) {
                        g_printerr("Unable to power off!");
                        g_error_free(error);
                }
        } else if (g_str_equal(data, "reboot")) {
                /* Reboot */
                sd_login_manager_call_reboot_sync(self->proxy, TRUE, NULL, &error);
                if (error) {
                        g_printerr("Unable to reboot!");
                        g_error_free(error);
                }
        } else if (g_str_equal(data, "suspend")) {
                /* Suspend */
                sd_login_manager_call_suspend_sync(self->proxy, TRUE, NULL, &error);
                if (error) {
                        g_printerr("Unable to suspend!");
                        g_error_free(error);
                }
        } else if (g_str_equal(data, "logout")) {
                if (!g_spawn_command_line_async("budgie-session --logout", NULL)) {
                        g_message("Unable to logout!");
                }
        }
        gtk_main_quit();
}

static void init_styles(BudgieSessionDialog *self)
{
        GtkCssProvider *css_provider;
        GFile *file = NULL;
        GdkScreen *screen;

        screen = gdk_screen_get_default();

        /* Fallback */
        css_provider = gtk_css_provider_new();
        file = g_file_new_for_uri("resource://com/evolve-os/budgie/session/dialog.css");
        if (gtk_css_provider_load_from_file(css_provider, file, NULL)) {
                gtk_style_context_add_provider_for_screen(screen,
                        GTK_STYLE_PROVIDER(css_provider),
                        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
        g_object_unref(css_provider);
        g_object_unref(file);
}
