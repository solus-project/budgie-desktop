/*
 * budgie-panel.c
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <gmenu-tree.h>
#include <string.h>

#include "budgie-panel.h"
#include "applets/power-applet.h"
#include "applets/menu-applet.h"
#include "applets/clock-applet.h"
#include "applets/sound-applet.h"
#include "applets/windowlist-applet.h"

G_DEFINE_TYPE(BudgiePanel, budgie_panel, GTK_TYPE_WINDOW)

#define PANEL_HEIGHT 45

/* Boilerplate GObject code */
static void budgie_panel_class_init(BudgiePanelClass *klass);
static void budgie_panel_init(BudgiePanel *self);
static void budgie_panel_dispose(GObject *object);
static void settings_cb(GSettings *settings,
                        gchar *key,
                        gpointer userdata);
static gboolean budgie_panel_draw(GtkWidget *widget,
                                  cairo_t *cr,
                                  gpointer userdata);
/* Private methods */
static void init_styles(BudgiePanel *self);

/* Initialisation */
static void budgie_panel_class_init(BudgiePanelClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_panel_dispose;
}

static void realized_cb(GtkWidget *widget, gpointer userdata)
{
        BudgiePanel *self;
        GdkScreen *screen;
        int height, x, y;
        GtkAllocation alloc;
        GdkWindow *window;
        long vals[4];
        GdkAtom atom;

        self = BUDGIE_PANEL(userdata);
        screen = gtk_widget_get_screen(widget);
        height = gdk_screen_get_height(screen);

        gtk_widget_get_allocation(widget, &alloc);
        x = 0;

        /* Place at bottom or top */
        if (self->position == PANEL_BOTTOM) {
                y = (height - alloc.height)+1;
        } else {
                y = 0;
        }

        gtk_window_move(GTK_WINDOW(self), x, y);

        vals[0] = 0;
        vals[1] = 0;
        if (self->position == PANEL_BOTTOM){
            vals[2] = 0;
            vals[3] = alloc.height;
        }else {
            vals[2] = alloc.height;
            vals[3] = 0;
        }

        /* Reserve space for the bar with the window manager */
        atom = gdk_atom_intern ("_NET_WM_STRUT", FALSE);
        window = gtk_widget_get_window(GTK_WIDGET(widget));
        if (window){
            gdk_property_change (window, atom, gdk_atom_intern("CARDINAL", FALSE), 
                            32, GDK_PROP_MODE_REPLACE, (guchar *)vals, 4);
        }

        gtk_widget_queue_draw(GTK_WIDGET(self));
}


static void resized_cb(GtkWidget *widget,
                       GdkRectangle *rectangle,
                       gpointer userdata)
{
        GtkAllocation alloc;

        /* Make sure we're in the right place (screen bottom) */
        gtk_widget_get_allocation(widget, &alloc);
                realized_cb(widget, userdata);
}

static void budgie_panel_init(BudgiePanel *self)
{
        GtkWidget *tasklist;
        GtkWidget *layout;
        GtkWidget *widgets;
        GdkScreen *screen;
        GdkDisplay *display;
        GdkVisual *visual;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *sound;
        GtkWidget *menu;
        int width;
        GSettings *gsettings;
        GtkStyleContext *style;

        init_styles(self);

        /* Controlled by GSettings */
        self->position = PANEL_BOTTOM;

        gsettings = g_settings_new(BUDGIE_SCHEMA);
        self->settings = gsettings;
        settings_cb(gsettings, BUDGIE_PANEL_LOCATION, self);
        g_signal_connect(gsettings, "changed", G_CALLBACK(settings_cb), self);

        /* Sort ourselves out visually */
        style = gtk_widget_get_style_context(GTK_WIDGET(self));
        gtk_style_context_add_class(style, BUDGIE_STYLE_PANEL);
        gtk_style_context_remove_class(style, "background");
        gtk_widget_set_app_paintable(GTK_WIDGET(self), TRUE);
        g_signal_connect(self, "draw", G_CALLBACK(budgie_panel_draw), self);

        /* Not resizable.. */
        gtk_window_set_resizable(GTK_WINDOW(self), FALSE);
        gtk_window_set_has_resize_grip(GTK_WINDOW(self), FALSE);

        /* Decide if we're using X11 or Wayland */
        display = gdk_display_get_default();
        if (GDK_IS_X11_DISPLAY(display)) {
                self->x11 = TRUE;
        } else {
                self->x11 = FALSE;
        }

        /* Our main layout is a horizontal box */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_widget_set_valign(layout, GTK_ALIGN_START);
        gtk_container_add(GTK_CONTAINER(self), layout);

        g_object_set(layout, "margin-top", 3, NULL);

        /* Add a menu button */
        menu = menu_applet_new();
        self->menu = menu;
        gtk_box_pack_start(GTK_BOX(layout), menu, FALSE, FALSE, 0);
        g_object_set(menu, "margin-left", 4+11, NULL);

        /* Add a tasklist to the panel on x11 */
        if (self->x11) {
                tasklist = windowlist_applet_new();
                self->tasklist = tasklist;
                gtk_box_pack_start(GTK_BOX(layout), tasklist, FALSE, FALSE, 0);
        }

        /* Group widgets under one area */
        widgets = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 5);
        /* Now have it themed by eventbox */
        g_signal_connect(widgets, "draw", G_CALLBACK(budgie_panel_draw), self);

        gtk_widget_set_valign(widgets, GTK_ALIGN_FILL);
        g_object_set(widgets, "margin", 5, NULL);
        style = gtk_widget_get_style_context(widgets);
        gtk_style_context_add_class(style, BUDGIE_STYLE_MESSAGE_AREA);

        gtk_box_pack_end(GTK_BOX(layout), widgets, FALSE, FALSE, 0);

        /* Add the power applet  */
        power = power_applet_new();
        self->power = power;
        gtk_box_pack_start(GTK_BOX(widgets), power, FALSE, FALSE, 0);
        g_object_set(power, "margin-left", 3, NULL);

        /* And now the sound */
        sound = sound_applet_new();
        self->sound = sound;
        gtk_box_pack_start(GTK_BOX(widgets), sound, FALSE, FALSE, 0);
        g_object_set(sound, "margin-right", 3, NULL);

        /* Add a clock at the end */
        clock = clock_applet_new();
        self->clock = clock;
        g_object_set(clock, "margin-right", 1, NULL);
        gtk_box_pack_end(GTK_BOX(widgets), clock, FALSE, FALSE, 0);
        gtk_widget_set_valign(GTK_WIDGET(widgets), GTK_ALIGN_FILL);

        /* Ensure we close when destroyed */
        g_signal_connect(self, "destroy", G_CALLBACK(gtk_main_quit), NULL);


        /* Ensure we move to the right location when anything internally
         * changes size */
        g_signal_connect(self, "size-allocate", G_CALLBACK(resized_cb), self);

        /* Set ourselves up to be the correct size and position */
        screen = gdk_display_get_default_screen(display);
        visual = gdk_screen_get_rgba_visual(screen);
        if (visual) {
                gtk_widget_set_visual(GTK_WIDGET(self), visual);
        }

        width = gdk_screen_get_width(screen);
        gtk_widget_set_size_request(GTK_WIDGET(self), width, PANEL_HEIGHT);

        g_signal_connect(self, "realize", G_CALLBACK(realized_cb),
                self);

        /* On X11 use dock hint */
        if (self->x11) {
                gtk_window_set_type_hint(GTK_WINDOW(self),
                        GDK_WINDOW_TYPE_HINT_DOCK);
                gtk_window_stick(GTK_WINDOW(self));
        } else {
                gtk_window_set_decorated(GTK_WINDOW(self), FALSE);
        }

        /* And now show ourselves */
        gtk_widget_show_all(GTK_WIDGET(self));
}

static void budgie_panel_dispose(GObject *object)
{
        BudgiePanel *self = BUDGIE_PANEL(object);

        if (self->settings) {
                g_object_unref(self->settings);
                self->settings = NULL;
        }

        /* Destruct */
        G_OBJECT_CLASS (budgie_panel_parent_class)->dispose (object);
}

/* Utility; return a new BudgiePanel */
BudgiePanel *budgie_panel_new(void)
{
        BudgiePanel *self;

        self = g_object_new(BUDGIE_PANEL_TYPE, NULL);
        return self;
}

static void init_styles(BudgiePanel *self)
{
        GtkCssProvider *css_provider;
        GFile *file = NULL;
        GdkScreen *screen;

        screen = gdk_screen_get_default();

        /* Fallback */
        css_provider = gtk_css_provider_new();
        file = g_file_new_for_uri("resource://com/evolve-os/budgie/panel/style.css");
        if (gtk_css_provider_load_from_file(css_provider, file, NULL)) {
                gtk_style_context_add_provider_for_screen(screen,
                        GTK_STYLE_PROVIDER(css_provider),
                        GTK_STYLE_PROVIDER_PRIORITY_FALLBACK);
        }
        g_object_unref(css_provider);
        g_object_unref(file);

        /* Forced */
        css_provider = gtk_css_provider_new();
        file = g_file_new_for_uri("resource://com/evolve-os/budgie/panel/app.css");
        if (gtk_css_provider_load_from_file(css_provider, file, NULL)) {
                gtk_style_context_add_provider_for_screen(screen,
                        GTK_STYLE_PROVIDER(css_provider),
                        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
        g_object_unref(css_provider);
        g_object_unref(file);
}

static void settings_cb(GSettings *settings,
                        gchar *key,
                        gpointer userdata)
{
        BudgiePanel *self = BUDGIE_PANEL(userdata);
        GtkStyleContext *style;
        gchar *value = NULL;

        /* Panel location */
        if (g_str_equal(key, BUDGIE_PANEL_LOCATION)) {
                value = g_settings_get_string(settings, key);
                style = gtk_widget_get_style_context(GTK_WIDGET(userdata));
                /* top or bottom location */
                if (g_str_equal(value, PANEL_TOP_KEY)) {
                        self->position = PANEL_TOP;
                        gtk_style_context_add_class(style, BUDGIE_STYLE_PANEL_TOP);
                } else {
                        self->position = PANEL_BOTTOM;
                        gtk_style_context_remove_class(style, BUDGIE_STYLE_PANEL_TOP);
                }
                realized_cb(userdata, userdata);
        }
}

static gboolean budgie_panel_draw(GtkWidget *widget,
                                  cairo_t *cr,
                                  gpointer userdata)
{
        GtkStyleContext *style;
        GtkAllocation alloc;

        gtk_widget_get_allocation(widget, &alloc);

        style = gtk_widget_get_style_context(widget);
        gtk_render_background(style, cr, 0, 0, alloc.width, alloc.height);
        gtk_render_frame(style, cr, 0, 0, alloc.width, alloc.height);
        if (GTK_IS_BIN(widget)) {
                gtk_container_propagate_draw(GTK_CONTAINER(widget), gtk_bin_get_child(GTK_BIN(widget)), cr);
                return TRUE;
        }

        return FALSE;
}
