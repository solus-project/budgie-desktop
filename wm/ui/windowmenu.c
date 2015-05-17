/*
 * windowmenu.c
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <meta/window.h>
#include <gtk/gtk.h>
#include "windowmenu.h"


struct _BudgieWindowMenuPrivate
{
        MetaWindow *window;
        GtkWidget *minimize;
        GtkWidget *maximize;
        GtkWidget *unmaximize;
        GtkWidget *close;
        GtkWidget *move;
        GtkWidget *resize;
        GtkWidget *above;
};

G_DEFINE_TYPE_WITH_PRIVATE(BudgieWindowMenu, budgie_window_menu, GTK_TYPE_MENU)

/* Boilerplate GObject code */
static void budgie_window_menu_class_init(BudgieWindowMenuClass *klass);
static void budgie_window_menu_init(BudgieWindowMenu *self);
static void budgie_window_menu_dispose(GObject *object);

enum {
        PROP_0, PROP_WINDOW, N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL,};
static void update_from_window(BudgieWindowMenu *self);

static void budgie_window_menu_set_property(GObject *object,
                                           guint prop_id,
                                           const GValue *value,
                                           GParamSpec *pspec)
{
        BudgieWindowMenu *self;

        self = BUDGIE_WINDOW_MENU(object);
        switch (prop_id) {
                case PROP_WINDOW:
                        self->priv->window = g_value_get_pointer((GValue*)value);
                        update_from_window(self);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
                                prop_id, pspec);
                        break;
        }
}

static void budgie_window_menu_get_property(GObject *object,
                                           guint prop_id,
                                           GValue *value,
                                           GParamSpec *pspec)
{
        BudgieWindowMenu *self;

        self = BUDGIE_WINDOW_MENU(object);
        switch (prop_id) {
                case PROP_WINDOW:
                        g_value_set_pointer((GValue *)value, self->priv->window);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
                                prop_id, pspec);
                        break;
        }
}

/* Initialisation */
static void budgie_window_menu_class_init(BudgieWindowMenuClass *klass)
{
        GObjectClass *g_object_class;
        obj_properties[PROP_WINDOW] =
        g_param_spec_pointer("window", "Window", "Window",
                G_PARAM_READWRITE);

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_window_menu_dispose;
        g_object_class->set_property = &budgie_window_menu_set_property;
        g_object_class->get_property = &budgie_window_menu_get_property;
        g_object_class_install_properties(g_object_class, N_PROPERTIES,
                obj_properties);
}

#define MAPPEND(x) gtk_widget_show(x) ; gtk_menu_shell_append(GTK_MENU_SHELL(self), x);

static void minimize_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_minimize(self->priv->window);
}

static void unmaximize_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_unmaximize(self->priv->window, META_MAXIMIZE_BOTH);
}

static void maximize_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_maximize(self->priv->window, META_MAXIMIZE_BOTH);
}

static void close_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_delete(self->priv->window, CLUTTER_CURRENT_TIME);
}

static void move_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_begin_grab_op(self->priv->window, META_GRAB_OP_KEYBOARD_MOVING, TRUE, CLUTTER_CURRENT_TIME);
}

static void resize_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        meta_window_begin_grab_op(self->priv->window, META_GRAB_OP_KEYBOARD_RESIZING_UNKNOWN, TRUE, CLUTTER_CURRENT_TIME);
}

static void above_cb(BudgieWindowMenu *self, GtkWidget *item)
{
        g_object_freeze_notify(G_OBJECT(item));
        if (meta_window_is_above(self->priv->window)) {
                meta_window_unmake_above(self->priv->window);
        } else {
                meta_window_make_above(self->priv->window);
        }
        g_object_thaw_notify(G_OBJECT(item));
}

static void budgie_window_menu_init(BudgieWindowMenu *self)
{
        GtkWidget *item = NULL;

        /* Initial boilerplate cruft. */
        self->priv = budgie_window_menu_get_instance_private(self);

        item = gtk_menu_item_new_with_label("Minimise");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(minimize_cb), self);
        self->priv->minimize = item;
        MAPPEND(item);


        item = gtk_menu_item_new_with_label("Unmaximize");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(unmaximize_cb), self);
        self->priv->unmaximize = item;
        MAPPEND(item);

        item = gtk_menu_item_new_with_label("Maximize");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(maximize_cb), self);
        self->priv->maximize = item;
        MAPPEND(item);

        item = gtk_menu_item_new_with_label("Move");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(move_cb), self);
        self->priv->move = item;
        MAPPEND(item);

        item = gtk_menu_item_new_with_label("Resize");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(resize_cb), self);
        self->priv->resize = item;
        MAPPEND(item);

        item = gtk_separator_menu_item_new();
        MAPPEND(item);


        item = gtk_menu_item_new_with_label("Always On Top");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(above_cb), self);
        self->priv->above = item;
        MAPPEND(item);

        item = gtk_separator_menu_item_new();
        MAPPEND(item);

        item = gtk_menu_item_new_with_label("Close");
        g_signal_connect_swapped(item, "activate", G_CALLBACK(close_cb), self);
        self->priv->close = item;
        MAPPEND(item);
}

static void budgie_window_menu_dispose(GObject *object)
{
        G_OBJECT_CLASS (budgie_window_menu_parent_class)->dispose (object);
}

/* Utility; return a new BudgieWindowMenu */
GtkWidget *budgie_window_menu_new()
{
        BudgieWindowMenu *self;

        self = g_object_new(BUDGIE_WINDOW_MENU_TYPE,  NULL);
        return GTK_WIDGET(self);
}

static void update_from_window(BudgieWindowMenu *self)
{
        MetaWindow *window = self->priv->window;
        if (!window) {
                return;
        }

        gtk_widget_set_sensitive(self->priv->minimize, meta_window_can_minimize(window));
        gtk_widget_set_sensitive(self->priv->maximize, meta_window_can_maximize(window));
        gtk_widget_set_sensitive(self->priv->close, meta_window_can_close(window));
        gtk_widget_set_sensitive(self->priv->move, meta_window_allows_move(window));
        gtk_widget_set_sensitive(self->priv->resize, meta_window_allows_resize(window));

        gtk_widget_set_visible(self->priv->unmaximize, meta_window_get_maximized(window));
        gtk_widget_set_visible(self->priv->maximize, !meta_window_get_maximized(window));

        gtk_widget_set_visible(self->priv->minimize, meta_window_can_minimize(window));
}
