/*
 * icon-tasklist.c
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

#include "icon-tasklist.h"

/* IconTasklist object */
struct _IconTasklist {
        GtkBox parent;
        WnckScreen *screen;
};

/* IconTasklist class definition */
struct _IconTasklistClass {
        GtkBoxClass parent_class;
};

G_DEFINE_TYPE(IconTasklist, icon_tasklist, GTK_TYPE_BOX)

/* Boilerplate GObject code */
static void icon_tasklist_class_init(IconTasklistClass *klass);
static void icon_tasklist_init(IconTasklist *self);
static void icon_tasklist_dispose(GObject *object);

/* Private functionality */
static gboolean button_draw(GtkWidget *widget,
                            cairo_t *cr,
                            gpointer userdata);
static gboolean button_on_click_cb(GtkWidget *widget,
                                    GdkEvent *event,
                                    gpointer data);

static void window_opened(WnckScreen *screen,
                          WnckWindow *window,
                          gpointer userdata);
static void window_closed(WnckScreen *screen,
                          WnckWindow *window,
                          gpointer userdata);
static void active_changed(WnckScreen *screen,
                           WnckWindow *prev_window,
                           gpointer userdata);

/* Initialisation */
static void icon_tasklist_class_init(IconTasklistClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &icon_tasklist_dispose;
}

static void icon_tasklist_init(IconTasklist *self)
{
        wnck_set_client_type(WNCK_CLIENT_TYPE_PAGER);
        self->screen = wnck_screen_get_default();
        g_signal_connect(self->screen, "window-opened",
                G_CALLBACK(window_opened), self);
        g_signal_connect(self->screen, "window-closed",
                G_CALLBACK(window_closed), self);
        g_signal_connect(self->screen, "active-window-changed",
                G_CALLBACK(active_changed), self);

        wnck_screen_force_update(self->screen);
        /* Align to the center vertically */
        gtk_widget_set_valign(GTK_WIDGET(self), GTK_ALIGN_START);
}

static void icon_tasklist_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (icon_tasklist_parent_class)->dispose (object);
        wnck_shutdown();
}

/* Utility; return a new IconTasklist */
GtkWidget *icon_tasklist_new(void)
{
        IconTasklist *self;

        self = g_object_new(ICON_TASKLIST_TYPE, NULL, "orientation", GTK_ORIENTATION_HORIZONTAL);
        return GTK_WIDGET(self);
}

static gboolean button_draw(GtkWidget *widget,
                            cairo_t *cr,
                            gpointer userdata)
{
        GtkAllocation alloc;
        gtk_widget_get_allocation(widget, &alloc);

        /* Draw children of the button (i.e image) */
        gtk_container_propagate_draw(GTK_CONTAINER(widget),
                gtk_bin_get_child(GTK_BIN(widget)),
                cr);

        if (!gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(widget)))
                return TRUE;

        /* Active window, render a partially transparent white line */
        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.8);
        cairo_rectangle(cr, 0, alloc.height-2, alloc.width, 2);
        cairo_fill(cr);

        /* Render button differently */
        return TRUE;
}

static gboolean button_on_click_cb(GtkWidget *widget,
                                     GdkEvent *event,
                                     gpointer data)
{
        WnckWindow *bwindow = NULL;
        guint32 timestamp = gtk_get_current_event_time();

        if(event->type == GDK_BUTTON_PRESS)
        {
                bwindow = (WnckWindow*)g_object_get_data(G_OBJECT(widget),
                                                         "bwindow");
                /* Something happen! return here. */
                if(bwindow == NULL)
                        return TRUE;

                if(wnck_window_is_minimized(bwindow))
                {
                        wnck_window_unminimize(bwindow, timestamp);
                        wnck_window_activate(bwindow, timestamp);
                }
                else
                {
                        if(wnck_window_is_active(bwindow))
                                wnck_window_minimize(bwindow);
                        else
                                wnck_window_activate(bwindow, timestamp);
                }
        }
        return FALSE;
}

static void window_opened(WnckScreen *screen,
                          WnckWindow *window,
                          gpointer userdata)
{
        GtkWidget *button = NULL;
        GtkWidget *image = NULL;
        const gchar *title;
        const gchar *icon;
        IconTasklist *self = ICON_TASKLIST(userdata);

        /* Don't add buttons for tasklist skipping apps */
        if (wnck_window_is_skip_tasklist(window))
                return;

        title = wnck_window_get_name(window);
        icon = wnck_window_get_icon_name(window);

        /* Add the image as a primary component */
        if (!wnck_window_has_icon_name(window))
                image = gtk_image_new_from_icon_name(icon, GTK_ICON_SIZE_BUTTON);
        else
                image = gtk_image_new_from_pixbuf(wnck_window_get_icon(window));

        button = gtk_toggle_button_new();
        gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
        gtk_container_add(GTK_CONTAINER(button), image);

        /* Set title as tooltip */
        gtk_widget_set_tooltip_text(button, title);

        /* Press it if its active */
        if (wnck_window_is_active(window))
                gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(button), TRUE);

        /* Store a reference to this window for destroy ops, etc. */
        g_object_set_data(G_OBJECT(button), "bwindow", window);

        /* Override drawing of this button */
        g_signal_connect(button, "draw", G_CALLBACK(button_draw), self);

        /* Clicking the button */
        g_signal_connect(button, "button-press-event",
                         G_CALLBACK(button_on_click_cb),
                         self);

        gtk_box_pack_start(GTK_BOX(self), button, FALSE, FALSE, 0);
        gtk_widget_show_all(button);
}

static void window_closed(WnckScreen *screen,
                          WnckWindow *window,
                          gpointer userdata)
{
        IconTasklist *self = ICON_TASKLIST(userdata);
        GList *list, *elem;
        GtkWidget *toggle;
        WnckWindow *bwindow;

        /* If a buttons window matches the closing window, destroy the button */
        list = gtk_container_get_children(GTK_CONTAINER(self));
        for (elem = list; elem; elem = elem->next) {
                if (!GTK_IS_TOGGLE_BUTTON(elem->data))
                        continue;
                toggle = GTK_WIDGET(elem->data);
                bwindow = (WnckWindow*)g_object_get_data(G_OBJECT(toggle), "bwindow");
                if (bwindow == window)
                        gtk_widget_destroy(toggle);
        }
}

static void active_changed(WnckScreen *screen,
                           WnckWindow *prev_window,
                           gpointer userdata)
{
        IconTasklist *self = ICON_TASKLIST(userdata);
        GList *list, *elem;
        GtkWidget *toggle;
        WnckWindow *bwindow, *active;

        active = wnck_screen_get_active_window(screen);

        /* If a buttons window matches the closing window, destroy the button */
        list = gtk_container_get_children(GTK_CONTAINER(self));
        for (elem = list; elem; elem = elem->next) {
                if (!GTK_IS_TOGGLE_BUTTON(elem->data))
                        continue;
                toggle = GTK_WIDGET(elem->data);
                bwindow = (WnckWindow*)g_object_get_data(G_OBJECT(toggle), "bwindow");
                /* Deselect previous window */
                if (bwindow == prev_window)
                        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(toggle), FALSE);
                /* Select new active window */
                if (bwindow == active)
                        gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(toggle), TRUE);
        }
}
