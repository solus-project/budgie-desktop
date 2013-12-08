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

#include <libwnck/libwnck.h>
#include <string.h>

#include "budgie-panel.h"
#include "applets/power-applet.h"

G_DEFINE_TYPE(BudgiePanel, budgie_panel, GTK_TYPE_WINDOW)

#define PANEL_HEIGHT 25

/* Boilerplate GObject code */
static void budgie_panel_class_init(BudgiePanelClass *klass);
static void budgie_panel_init(BudgiePanel *self);
static void budgie_panel_dispose(GObject *object);

/* Private methods */
static gboolean update_clock(gpointer userdata);
static void init_styles(BudgiePanel *self);

static gboolean draw_shadow(GtkWidget *widget,
                        cairo_t *cr,
                        gpointer userdata)
{
        GtkStyleContext *style;
        GtkAllocation alloc;

        style = gtk_widget_get_style_context(widget);
        gtk_widget_get_allocation(widget, &alloc);
        gtk_render_background(style, cr, alloc.x, alloc.y,
                alloc.width, alloc.height);

        return TRUE;
}

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
        int width, height, x, y;
        GtkAllocation alloc;

        self = BUDGIE_PANEL(userdata);
        screen = gtk_widget_get_screen(widget);
        width = gdk_screen_get_width(screen);
        height = gdk_screen_get_height(screen);

        gtk_widget_get_allocation(widget, &alloc);
        x = 0;
        y = height - alloc.height;
        gtk_window_move(GTK_WINDOW(self), x, y);
        gtk_window_move(GTK_WINDOW(self->shadow), x, y-4);
}

static void budgie_panel_init(BudgiePanel *self)
{
        GtkWidget *tasklist;
        GtkWidget *layout;
        GdkScreen *screen;
        GdkVisual *visual;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *menu;
        GtkWidget *shadow;
        int width;
        GtkSettings *settings;
        GtkStyleContext *style;

        init_styles(self);
        /* Sort ourselves out visually */
        settings = gtk_widget_get_settings(GTK_WIDGET(self));
        g_object_set(settings, "gtk-application-prefer-dark-theme",
                TRUE, NULL);

        /* Not resizable.. */
        gtk_window_set_resizable(GTK_WINDOW(self), FALSE);
        gtk_window_set_has_resize_grip(GTK_WINDOW(self), FALSE);

        /* tiny bit of padding */
        gtk_container_set_border_width(GTK_CONTAINER(self), 2);

        /* Our main layout is a horizontal box */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_container_add(GTK_CONTAINER(self), layout);

        /* Add a menu button */
        menu = gtk_button_new_with_label("Menu");
        gtk_button_set_relief(GTK_BUTTON(menu), GTK_RELIEF_NONE);
        g_object_set(menu, "margin-left", 3, "margin-right", 15, NULL);
        gtk_box_pack_start(GTK_BOX(layout), menu, FALSE, FALSE, 0);

        /* Add a tasklist to the panel */
        tasklist = wnck_tasklist_new();
        self->tasklist = tasklist;
        wnck_tasklist_set_button_relief(WNCK_TASKLIST(tasklist),
                GTK_RELIEF_NONE);
        gtk_box_pack_start(GTK_BOX(layout), tasklist, FALSE, FALSE, 0);

        /* Add a clock at the end */
        clock = gtk_label_new("--");
        self->clock = clock;
        style = gtk_widget_get_style_context(clock);
        gtk_style_context_add_class(style, "panel-applet");
        g_object_set(clock, "margin-left", 3, "margin-right", 1, NULL);
        gtk_box_pack_end(GTK_BOX(layout), clock, FALSE, FALSE, 0);

        /* Add the power applet near the end */
        power = power_applet_new();
        self->power = power;
        gtk_box_pack_end(GTK_BOX(layout), power, FALSE, FALSE, 0);

        /* Ensure we close when destroyed */
        g_signal_connect(self, "destroy", G_CALLBACK(gtk_main_quit), NULL);

        /* Set ourselves up to be the correct size and position */
        screen = gdk_screen_get_default();
        visual = gdk_screen_get_rgba_visual(screen);
        if (visual)
                gtk_widget_set_visual(GTK_WIDGET(self), visual);

        width = gdk_screen_get_width(screen);
        gtk_widget_set_size_request(GTK_WIDGET(self), width, PANEL_HEIGHT);

        /* We want to be a dock */
        gtk_window_set_type_hint(GTK_WINDOW(self),
                GDK_WINDOW_TYPE_HINT_DOCK);
        gtk_window_stick(GTK_WINDOW(self));

        g_signal_connect(self, "realize", G_CALLBACK(realized_cb),
                (gpointer)self);

        /* Add a shadow, idea came from wingpanel, kudos guys :) */
        shadow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
        self->shadow = shadow;
        gtk_window_set_type_hint(GTK_WINDOW(shadow),
                GDK_WINDOW_TYPE_HINT_DOCK);
        gtk_widget_set_size_request(GTK_WIDGET(shadow), width, 4);
        style = gtk_widget_get_style_context(shadow);
        gtk_style_context_add_class(style, "panel-shadow");
        gtk_window_stick(GTK_WINDOW(shadow));
        gtk_widget_set_visual(shadow, visual);
        g_signal_connect(shadow, "draw", G_CALLBACK(draw_shadow),
                (gpointer)self);
        gtk_widget_show_all(shadow);

        /* And now show ourselves */
        gtk_widget_show_all(GTK_WIDGET(self));

        /* Don't show an empty label */
        update_clock((gpointer)self);
        /* Update the clock every second */
        g_timeout_add(1000, update_clock, (gpointer)self);
}

static void budgie_panel_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (budgie_panel_parent_class)->dispose (object);
}

/* Utility; return a new BudgiePanel */
BudgiePanel* budgie_panel_new(void)
{
        BudgiePanel *self;

        self = g_object_new(BUDGIE_PANEL_TYPE, NULL);
        return self;
}

static void init_styles(BudgiePanel *self)
{
        GtkCssProvider *css_provider;
        GdkScreen *screen;
        const gchar *data = PANEL_CSS;

        css_provider = gtk_css_provider_new();
        gtk_css_provider_load_from_data(css_provider, data, (gssize)strlen(data)+1, NULL);
        screen = gdk_screen_get_default();
        gtk_style_context_add_provider_for_screen(screen, GTK_STYLE_PROVIDER(css_provider),
                GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

static gboolean update_clock(gpointer userdata)
{
        BudgiePanel *self;;
        gchar *date_string;
        GDateTime *dtime;

        self = BUDGIE_PANEL(userdata);

        /* Get the current time */
        dtime = g_date_time_new_now_local();

        /* Format it as a string (24h) */
        date_string = g_date_time_format(dtime, " %H:%M:%S <small>%x</small> ");
        gtk_label_set_markup(GTK_LABEL(self->clock), date_string);
        g_free(date_string);
        g_date_time_unref(dtime);

        return TRUE;
}
