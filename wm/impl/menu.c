/*
 * menu.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <gtk/gtk.h>

#include <gio/gdesktopappinfo.h>

#include "impl.h"
#include "plugin.h"


static gboolean launch_desktop(const gchar *name)
{
        GDesktopAppInfo *info = NULL;
        GError *error = NULL;

        info = g_desktop_app_info_new(name);
        if (!info) {
                return FALSE;
        }
        if (!g_app_info_launch(G_APP_INFO(info), NULL, NULL, &error)) {
                if (error) {
                        g_printerr("Error launching %s: %s\n", name, error->message);
                        g_object_unref(info);
                        g_error_free(error);
                        return FALSE;
                }
        }
        g_object_unref(info);
        return TRUE;
}

static gboolean on_button_press(ClutterActor *actor, ClutterEvent *event, BudgieWM *self)
{
        if (event->button.button != 3) {
                return CLUTTER_EVENT_PROPAGATE;
        }
        if (gtk_widget_get_visible(self->priv->menu)) {
                gtk_widget_hide(self->priv->menu);
        } else {
                gtk_menu_popup(GTK_MENU(self->priv->menu), NULL, NULL, NULL, NULL, event->button.button, event->button.time);
        }
        return CLUTTER_EVENT_STOP;
}

static void bg_change_cb(GtkWidget *widget, BudgieWM *self)
{
        launch_desktop("gnome-background-panel.desktop");
}

static void settings_change_cb(GtkWidget *widget, BudgieWM *self)
{
        launch_desktop("gnome-control-center.desktop");
}


void budgie_menus_init(BudgieWM *self)
{
        GtkWidget *menu = NULL;
        GtkWidget *item = NULL;

        menu = gtk_menu_new();
        self->priv->menu = menu;
        item = gtk_menu_item_new_with_label("Change background...");
        g_signal_connect(item, "activate", G_CALLBACK(bg_change_cb), self);
        gtk_widget_show(item);
        gtk_widget_show(menu);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);

        item = gtk_separator_menu_item_new();
        gtk_widget_show(item);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);

        item = gtk_menu_item_new_with_label("Settings");
        g_signal_connect(item, "activate", G_CALLBACK(settings_change_cb), self);
        gtk_widget_show(item);
        gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);

        g_signal_connect(self->priv->background_group, "button-release-event",
            G_CALLBACK(on_button_press), self);
}

void budgie_menus_end(BudgieWM *self)
{
        if (self->priv->menu) {
                gtk_widget_destroy(self->priv->menu);
                self->priv->menu = NULL;
        }
}
