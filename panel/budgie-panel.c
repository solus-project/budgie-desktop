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

#include <gmenu-tree.h>
#include <string.h>

#include "budgie-panel.h"
#include "applets/power-applet.h"
#include "applets/menu-applet.h"
#include "applets/clock-applet.h"
#include "applets/windowlist-applet.h"

/* X11 specific */
#include "xutils.h"

G_DEFINE_TYPE(BudgiePanel, budgie_panel, GTK_TYPE_WINDOW)

#define PANEL_HEIGHT 45

/* Boilerplate GObject code */
static void budgie_panel_class_init(BudgiePanelClass *klass);
static void budgie_panel_init(BudgiePanel *self);
static void budgie_panel_dispose(GObject *object);
static void settings_cb(GSettings *settings,
                        gchar *key,
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

        self = BUDGIE_PANEL(userdata);
        screen = gtk_widget_get_screen(widget);
        height = gdk_screen_get_height(screen);

        gtk_widget_get_allocation(widget, &alloc);
        x = 0;

        /* Place at bottom or top */
        if (self->position == PANEL_BOTTOM)
                y = height - alloc.height;
        else
                y = 0;

        gtk_window_move(GTK_WINDOW(self), x, y);

        /* Reserve struts on X11 display */
        if (self->x11) {
                window = gtk_widget_get_window(GTK_WIDGET(self));
                /* Bottom or top strut */
                if (window) {
                        if (self->position == PANEL_BOTTOM)
                                xstuff_set_wmspec_strut(window, 0, 0, 0, alloc.height);
                        else
                                xstuff_set_wmspec_strut(window, 0, 0, alloc.height, 0);
                }
        }
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
        GtkWidget *widgets, *widgets_wrap;
        GdkScreen *screen;
        GdkDisplay *display;
        GdkVisual *visual;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *menu;
        int width;
        GtkSettings *settings;
        GSettings *gsettings;

        init_styles(self);

        /* Controlled by GSettings */
        self->position = PANEL_BOTTOM;

        gsettings = g_settings_new(BUDGIE_SCHEMA);
        self->settings = gsettings;
        settings_cb(gsettings, BUDGIE_PANEL_LOCATION, self);
        g_signal_connect(gsettings, "changed", G_CALLBACK(settings_cb), self);

        /* Sort ourselves out visually */
        settings = gtk_widget_get_settings(GTK_WIDGET(self));
        g_object_set(settings,
                "gtk-application-prefer-dark-theme", TRUE,
                "gtk-menu-images", TRUE,
                "gtk-button-images", TRUE,
                NULL);

        /* Not resizable.. */
        gtk_window_set_resizable(GTK_WINDOW(self), FALSE);
        gtk_window_set_has_resize_grip(GTK_WINDOW(self), FALSE);

        /* Decide if we're using X11 or Wayland */
        display = gdk_display_get_default();
        if (GDK_IS_X11_DISPLAY(display))
                self->x11 = TRUE;
        else
                self->x11 = FALSE;

        /* Our main layout is a horizontal box */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
        gtk_widget_set_valign(layout, GTK_ALIGN_START);
        gtk_container_add(GTK_CONTAINER(self), layout);

        /* Add a menu button */
        menu = menu_applet_new();
        self->menu = menu;
        gtk_box_pack_start(GTK_BOX(layout), menu, FALSE, FALSE, 0);

        /* Add a tasklist to the panel on x11 */
        if (self->x11) {
                tasklist = windowlist_applet_new();
                self->tasklist = tasklist;
                gtk_box_pack_start(GTK_BOX(layout), tasklist, FALSE, FALSE, 0);
        }

        /* Group widgets under one area */
        widgets = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 5);
        /* Now have it themed by eventbox */
        widgets_wrap = gtk_event_box_new();
        g_object_set(widgets_wrap, "margin-right", 2, NULL);
        g_object_set(widgets, "margin", 5, NULL);
        gtk_widget_set_valign(widgets_wrap, GTK_ALIGN_CENTER);
        gtk_widget_set_name(widgets_wrap, "WidgetBox");
        gtk_container_add(GTK_CONTAINER(widgets_wrap), widgets);
        gtk_box_pack_end(GTK_BOX(layout), widgets_wrap, FALSE, FALSE, 0);

        /* Add a clock at the end */
        clock = clock_applet_new();
        self->clock = clock;
        g_object_set(clock, "margin-left", 3, "margin-right", 1, NULL);
        gtk_box_pack_start(GTK_BOX(widgets), clock, FALSE, FALSE, 0);

        /* Add the power applet near the end */
        power = power_applet_new();
        self->power = power;
        gtk_box_pack_end(GTK_BOX(widgets), power, FALSE, FALSE, 0);

        /* Ensure we close when destroyed */
        g_signal_connect(self, "destroy", G_CALLBACK(gtk_main_quit), NULL);


        /* Ensure we move to the right location when anything internally
         * changes size */
        g_signal_connect(self, "size-allocate", G_CALLBACK(resized_cb), self);

        /* Set ourselves up to be the correct size and position */
        screen = gdk_display_get_default_screen(display);
        visual = gdk_screen_get_rgba_visual(screen);
        if (visual)
                gtk_widget_set_visual(GTK_WIDGET(self), visual);

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
        gtk_css_provider_load_from_data(css_provider, data,
                (gssize)strlen(data)+1, NULL);
        screen = gdk_screen_get_default();
        gtk_style_context_add_provider_for_screen(screen,
                GTK_STYLE_PROVIDER(css_provider),
                GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
}

static void settings_cb(GSettings *settings,
                        gchar *key,
                        gpointer userdata)
{
        BudgiePanel *self = BUDGIE_PANEL(userdata);
        gchar *value = NULL;

        /* Panel location */
        if (g_str_equal(key, BUDGIE_PANEL_LOCATION)) {
                value = g_settings_get_string(settings, key);
                /* top or bottom location */
                if (g_str_equal(value, PANEL_TOP_KEY))
                        self->position = PANEL_TOP;
                else
                        self->position = PANEL_BOTTOM;
                realized_cb(userdata, userdata);
        }
}
