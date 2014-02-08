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

G_DEFINE_TYPE(PanelToplevel, panel_toplevel, GTK_TYPE_WINDOW)

#define PANEL_HEIGHT 25

/* Boilerplate GObject code */
static void panel_toplevel_class_init(PanelToplevelClass *klass);
static void panel_toplevel_init(PanelToplevel *self);
static void panel_toplevel_dispose(GObject *object);

/* Private methods */
static void init_styles(PanelToplevel *self);

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
static void panel_toplevel_class_init(PanelToplevelClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &panel_toplevel_dispose;
}

static void realized_cb(GtkWidget *widget, gpointer userdata)
{
        PanelToplevel *self;
        GdkScreen *screen;
        int height, x, y;
        GtkAllocation alloc;
        GdkWindow *window;

        self = PANEL_TOPLEVEL(userdata);
        screen = gtk_widget_get_screen(widget);
        height = gdk_screen_get_height(screen);

        gtk_widget_get_allocation(widget, &alloc);
        x = 0;
        y = height - alloc.height;
        gtk_window_move(GTK_WINDOW(self), x, y);

        /* Reserve struts on X11 display and add fake shadow */
        if (self->x11) {
                gtk_window_move(GTK_WINDOW(self->shadow), x, y-4);
                window = gtk_widget_get_window(GTK_WIDGET(self));
                /* Bottom strut */
                xstuff_set_wmspec_strut(window, 0, 0, 0, alloc.height);
        }
}

static void panel_toplevel_init(PanelToplevel *self)
{
        GtkWidget *tasklist;
        GtkWidget *layout;
        GdkScreen *screen;
        GdkDisplay *display;
        GdkVisual *visual;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *shadow;
        GtkWidget *menu;
        int width;
        GtkStyleContext *style;

        init_styles(self);

        /* Not resizable.. */
        gtk_window_set_resizable(GTK_WINDOW(self), FALSE);
        gtk_window_set_has_resize_grip(GTK_WINDOW(self), FALSE);

        /* tiny bit of padding */
        gtk_container_set_border_width(GTK_CONTAINER(self), 2);

        /* Decide if we're using X11 or Wayland */
        display = gdk_display_get_default();
        if (GDK_IS_X11_DISPLAY(display))
                self->x11 = TRUE;
        else
                self->x11 = FALSE;

        /* Our main layout is a horizontal box */
        layout = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
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

        /* Add a clock at the end */
        clock = clock_applet_new();
        self->clock = clock;
        gtk_widget_set_name(clock, "BorderedApplet");
        g_object_set(clock, "margin-left", 3, "margin-right", 1, NULL);
        gtk_box_pack_end(GTK_BOX(layout), clock, FALSE, FALSE, 0);

        /* Add the power applet near the end */
        power = power_applet_new();
        self->power = power;
        gtk_box_pack_end(GTK_BOX(layout), power, FALSE, FALSE, 0);

        /* Ensure we close when destroyed */
        g_signal_connect(self, "destroy", G_CALLBACK(gtk_main_quit), NULL);


        /* Set ourselves up to be the correct size and position */
        screen = gdk_display_get_default_screen(display);
        visual = gdk_screen_get_rgba_visual(screen);
        if (visual)
                gtk_widget_set_visual(GTK_WIDGET(self), visual);

        width = gdk_screen_get_width(screen);
        gtk_widget_set_size_request(GTK_WIDGET(self), width, PANEL_HEIGHT);

        g_signal_connect(self, "realize", G_CALLBACK(realized_cb),
                self);

        /* Add a shadow, idea came from wingpanel, kudos guys :) */
        if (self->x11) {
                shadow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
                self->shadow = shadow;
                gtk_window_set_type_hint(GTK_WINDOW(shadow),
                        GDK_WINDOW_TYPE_HINT_DOCK);
                gtk_widget_set_size_request(GTK_WIDGET(shadow), width, 4);
                style = gtk_widget_get_style_context(shadow);
                gtk_style_context_add_class(style, "panel-shadow-bottom");
                gtk_window_stick(GTK_WINDOW(shadow));
                gtk_widget_set_visual(shadow, visual);
                g_signal_connect(shadow, "draw", G_CALLBACK(draw_shadow),
                        self);
                gtk_widget_show_all(shadow);

                /* We want to be a dock */
                gtk_window_set_type_hint(GTK_WINDOW(self),
                        GDK_WINDOW_TYPE_HINT_DOCK);
                gtk_window_stick(GTK_WINDOW(self));
        } else {
                gtk_window_set_decorated(GTK_WINDOW(self), FALSE);
        }

        /* And now show ourselves */
        gtk_widget_show_all(GTK_WIDGET(self));
}

static void panel_toplevel_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (panel_toplevel_parent_class)->dispose (object);
}

/* Utility; return a new PanelToplevel */
PanelToplevel* panel_toplevel_new(void)
{
        PanelToplevel *self;

        self = g_object_new(PANEL_TOPLEVEL_TYPE, NULL);
        return self;
}

static void init_styles(PanelToplevel *self)
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
                GTK_STYLE_PROVIDER_PRIORITY_FALLBACK);
}
