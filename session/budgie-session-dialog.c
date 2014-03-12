/*
 * budgie-session-dialog.c
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

#include "budgie-session-dialog.h"

G_DEFINE_TYPE(BudgieSessionDialog, budgie_session_dialog, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void budgie_session_dialog_class_init(BudgieSessionDialogClass *klass);
static void budgie_session_dialog_init(BudgieSessionDialog *self);
static void budgie_session_dialog_dispose(GObject *object);

static void init_styles(BudgieSessionDialog *self);

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
        gchar *txt = NULL;
        GtkStyleContext *style;

        init_styles(self);

        gtk_window_set_position(GTK_WINDOW(self), GTK_WIN_POS_CENTER_ALWAYS);
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
        g_free(txt);
        gtk_label_set_use_markup(GTK_LABEL(label), TRUE);
        gtk_box_pack_start(GTK_BOX(top), label, TRUE, TRUE, 0);

        /* Add some buttons to uh.. logout, etc. :) */
        button = gtk_button_new_with_label("Logout");
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);

        button = gtk_button_new_with_label("Reboot");
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);

        button = gtk_button_new_with_label("Poweroff");
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), button, FALSE, FALSE, 0);

        button = gtk_button_new_with_label("Cancel");
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
        /* Destruct */
        G_OBJECT_CLASS (budgie_session_dialog_parent_class)->dispose (object);
}

/* Utility; return a new BudgieSessionDialog */
BudgieSessionDialog* budgie_session_dialog_new(void)
{
        BudgieSessionDialog *self;

        self = g_object_new(BUDGIE_SESSION_DIALOG_TYPE, NULL);
        return self;
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
