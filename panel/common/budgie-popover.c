/*
 * budgie-popover.c
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

#include "budgie-popover.h"

G_DEFINE_TYPE(BudgiePopover, budgie_popover, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void budgie_popover_class_init(BudgiePopoverClass *klass);
static void budgie_popover_init(BudgiePopover *self);
static void budgie_popover_dispose(GObject *object);
static gboolean budgie_popover_draw(GtkWidget *widget,
                                    cairo_t *cr,
                                    gboolean userdata);
static void budgie_tail_path(cairo_t *cr,
                             gdouble gap1,
                             gdouble gap_width,
                             gdouble height,
                             gdouble tail_height,
                             gboolean top);

static gboolean focus_lose(GtkWidget *widget,
                           GdkEvent *event,
                           gpointer userdata);

static gboolean map_event(GtkWidget *widget,
                          GdkEvent *event,
                          gpointer userdata);
/* Initialisation */
static void budgie_popover_class_init(BudgiePopoverClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_popover_dispose;
}

static gboolean button_press(GtkWidget *widget, GdkEventButton *event, gpointer userdata)
{
        GtkAllocation alloc;
        gint x, y;

        gtk_window_get_position(GTK_WINDOW(widget), &x, &y);
        gtk_widget_get_allocation(widget, &alloc);

        if ( ((event->x < x || event->x+alloc.width>x)) ||
              ((event->y < y || event->y+alloc.height>y))) {
                      budgie_popover_hide(BUDGIE_POPOVER(userdata));
        }

        return FALSE;
}

static void budgie_popover_init(BudgiePopover *self)
{
        self->top = FALSE;
        /* We don't override as we need some GtkWindow rendering */
        g_signal_connect(self, "draw", G_CALLBACK(budgie_popover_draw), self);
        g_signal_connect(self, "key-press-event", G_CALLBACK(focus_lose), self);
        g_signal_connect(self, "map-event", G_CALLBACK(map_event), self);
        self->focus_id = g_signal_connect(self, "focus-out-event", G_CALLBACK(focus_lose), self);

        gtk_window_set_decorated(GTK_WINDOW(self), FALSE);
        gtk_widget_set_app_paintable(GTK_WIDGET(self), TRUE);

        /* Skip, no decorations, etc */
        gtk_window_set_skip_taskbar_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_skip_pager_hint(GTK_WINDOW(self), TRUE);
}

static void budgie_popover_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (budgie_popover_parent_class)->dispose (object);
}

/* Utility; return a new BudgiePopover */
GtkWidget *budgie_popover_new(void)
{
        BudgiePopover *self;

        self = g_object_new(BUDGIE_POPOVER_TYPE, NULL);
        return GTK_WIDGET(self);
}

void budgie_popover_hide(BudgiePopover *self)
{
        __attribute__ ((unused)) gboolean ret;
        /* tear us down */
        if (self->pointer) {
                gdk_device_ungrab(self->pointer, GDK_CURRENT_TIME);
                self->pointer = NULL;
        }
        gtk_widget_hide(GTK_WIDGET(self));
        if (self->con_id > 0 && self->parent_widget) {
                g_signal_handler_disconnect(self->parent_widget, self->con_id);
                self->parent_widget = NULL;
        }
        g_signal_handler_block(self, self->focus_id);
        g_signal_emit_by_name(self, "focus-out-event", NULL, &ret);
        g_signal_handler_unblock(self, self->focus_id);
        if (gtk_widget_get_realized(GTK_WIDGET(self))) {
                gtk_widget_unrealize(GTK_WIDGET(self));
        }
        self->con_id = 0;
}

static void __budgie_popover_draw(GtkWidget *widget,
                                  cairo_t *cr,
                                  gboolean draw)
{
        BudgiePopover *self = BUDGIE_POPOVER(widget);
        GtkStyleContext *style;
        GtkAllocation alloc;
        GtkPositionType gap_side;
        GdkRGBA color;
        gdouble x, y, tail_height, gap_width;
        gdouble width, height, gap1, gap2;

        x = 0;
        y = 0;
        tail_height = 12;
        gap_width = 24;

        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.0);
        cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
        cairo_paint(cr);

        style = gtk_widget_get_style_context(widget);
        gtk_style_context_add_class(style, GTK_STYLE_CLASS_FRAME);

        gtk_widget_get_allocation(widget, &alloc);
        /* Have parent class do drawing, so we gain shadows */
        ((GtkWidgetClass*)budgie_popover_parent_class)->draw(widget, cr);

        /* Remove height of tail, and margin, from our rendered size */
        width = alloc.width;
        height = alloc.height - tail_height;

        cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
        gap1 = (alloc.width/2)-(gap_width/2);
        gap1 = self->widg_x;
        gap2 = gap1 + gap_width;
        gap_side = self->top == TRUE ? GTK_POS_TOP : GTK_POS_BOTTOM;

        /* Render a gap in the bottom center for our arrow */
        gtk_render_frame_gap(style, cr, x, y, width, height,
                gap_side, gap1, gap2);
        /* Fill in the background (pre-clip) */
        gtk_render_background(style, cr, x, y, width, height);

        /* Clip to the tail, fill in the arrow background */
        cairo_save(cr);
        if (self->top) {
                budgie_tail_path(cr, gap1, gap_width, y, tail_height, self->top);
        } else {
                budgie_tail_path(cr, gap1, gap_width, height, tail_height, self->top);
        }
        cairo_clip(cr);
        if (self->top) {
                gtk_render_background(style, cr, x, y-tail_height, alloc.width, alloc.height);
        } else {
                gtk_render_background(style, cr, x, y, alloc.width, alloc.height);
        }
        cairo_restore(cr);

        /* Draw in the border */
        gtk_style_context_get_border_color(style, gtk_widget_get_state_flags(widget), &color);
        gdk_cairo_set_source_rgba(cr, &color);
        cairo_set_line_width(cr, 1);
        if (self->top) {
                budgie_tail_path(cr, gap1, gap_width, y, tail_height, self->top);
        } else {
                budgie_tail_path(cr, gap1, gap_width, height, tail_height, self->top);
        }
        cairo_stroke(cr);
}

static void __create_mask(GtkWidget *widget)
{
        cairo_surface_t *surf = NULL;
        cairo_t *cr = NULL;
        cairo_region_t *ct = NULL;
        GdkWindow *window = NULL;

        GtkAllocation alloc;

        gtk_widget_get_allocation(widget, &alloc);

        surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, alloc.width, alloc.height);
        cr = cairo_create(surf);
        cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.0);
        cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
        cairo_paint(cr);

        __budgie_popover_draw(widget, cr, TRUE);

        ct = gdk_cairo_region_create_from_surface(surf);
        window = gtk_widget_get_window(widget);
        gdk_window_shape_combine_region(window, ct, 0, 0);

        cairo_surface_destroy(surf);
        cairo_region_destroy(ct);
        cairo_destroy(cr);
}

static gboolean map_event(GtkWidget *widget,
                          GdkEvent *event,
                          gpointer userdata)
{
        __create_mask(widget);
        return FALSE;
}

static gboolean budgie_popover_draw(GtkWidget *widget,
                                    cairo_t *cr,
                                    gboolean draw)
{

        __budgie_popover_draw(widget, cr, draw);

        /* Draw children */
        gtk_container_propagate_draw(GTK_CONTAINER(widget),
                gtk_bin_get_child(GTK_BIN(widget)),
                cr);

        return TRUE;
}

static void budgie_tail_path(cairo_t *cr,
                             gdouble gap1,
                             gdouble gap_width,
                             gdouble height,
                             gdouble tail_height,
                             gboolean top)
{
        gdouble start_x, end_x, tip_x;
        gdouble start_y, end_y, tip_y;

        start_x = gap1;
        end_x = gap1 + gap_width;
        tip_x = start_x + (gap_width/2);

        if (top) {
                start_y = height+tail_height;
                tip_y = start_y - tail_height;
        } else {
                start_y = height - 1;
                tip_y = start_y + tail_height;
        }
        end_y = start_y;

        /* Draw a triangle, basically */
        cairo_move_to(cr, start_x, start_y);
        cairo_line_to(cr, tip_x, tip_y);
        cairo_line_to(cr, end_x, end_y);
}

/* Stolen from GtkMenu */
static gboolean popup_grab_on_window(GdkWindow *window,
                                     GdkDevice *keyboard,
                                     GdkDevice *pointer,
                                     guint32  activate_time)
{
        if (keyboard &&
                gdk_device_grab(keyboard, window,
                         GDK_OWNERSHIP_WINDOW, TRUE,
                         GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK,
                         NULL, activate_time) != GDK_GRAB_SUCCESS) {
                return FALSE;
        }

        if (pointer &&
                gdk_device_grab(pointer, window,
                                GDK_OWNERSHIP_WINDOW, TRUE,
                                GDK_SMOOTH_SCROLL_MASK |
                                GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK |
                                GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK |
                                GDK_POINTER_MOTION_MASK,
                                NULL, activate_time) != GDK_GRAB_SUCCESS) {
                if (keyboard) {
                        gdk_device_ungrab (keyboard, activate_time);
                }

                return FALSE;
        }

  return TRUE;
}

void budgie_popover_present(BudgiePopover *self,
                            GtkWidget *parent,
                            GdkEvent *event)
{
        GtkWidget *real_parent;
        GdkWindow *parent_window;
        gint x, y, tx, ty, rx, margin;
        GdkScreen *screen;
        GtkAllocation alloc, our_alloc;
        GdkDeviceManager *manager;
        gint32 time;

        if (event && event->type == GDK_BUTTON_PRESS) {
                x = event->button.x;
                y = event->button.y;
        } else if (event && event->type == GDK_TOUCH_END) {
                x = event->touch.x;
                y = event->touch.y;
        }

        if (gtk_widget_get_visible(GTK_WIDGET(self))) {
                budgie_popover_hide(self);
                return;
        }
        if (!gtk_widget_get_realized(GTK_WIDGET(self))) {
                gtk_widget_realize(GTK_WIDGET(self));
        }

        /* Get position of parent widget on screen */
        real_parent = gtk_widget_get_toplevel(parent);
        parent_window = gtk_widget_get_window(real_parent);
        gdk_window_get_position(parent_window, &x, &y);
        gtk_widget_translate_coordinates(parent, real_parent, x, y, &tx, &ty);

        gtk_widget_get_allocation(parent, &alloc);
        gtk_widget_get_allocation(GTK_WIDGET(self), &our_alloc);
        screen = gtk_widget_get_screen(GTK_WIDGET(self));

        /* Ensure we're in a sensible position (under/over) */
        if (ty + our_alloc.height + 11 < gdk_screen_get_height(screen)) {
                self->top = TRUE;
                ty = y+alloc.y+alloc.height;
        } else {
                ty = (y+alloc.y)-our_alloc.height;
                self->top = FALSE;
        }

        /* Ensure widg_x is within bounds */
        if (event) {
                /* Point tip to mouse x,y */
                rx = x;
        } else {
                /* Center the tip when there is no event */
                rx = alloc.x + (alloc.width/2);
        }
        /* ensure margin is accounted for */
        g_object_get(parent, "margin", &margin, NULL);
        tx -= margin;
        rx -= margin;
        if (rx >= our_alloc.width) {
                rx = our_alloc.width - 20;
        }
        if (rx <= 20) {
                rx = 20;
        }
        self->widg_x = rx;


        gtk_window_move(GTK_WINDOW(self), tx-11, ty);
        gtk_widget_show_all(GTK_WIDGET(self));
        if (event) {
                if (event->type == GDK_BUTTON_PRESS) {
                        self->pointer = event->button.device;
                        time = event->button.time;
                } else {
                        self->pointer = event->touch.device;
                        time = event->touch.time;
                }
        } else {
                manager = gdk_display_get_device_manager(gdk_screen_get_display(screen));
                self->pointer = gdk_device_manager_get_client_pointer(manager);
                time = GDK_CURRENT_TIME;
        }
        self->parent_widget = real_parent;
        self->con_id = g_signal_connect(real_parent, "button-press-event", G_CALLBACK(button_press), self);
        self->con_id = 0;
        /* TODO: Handle keyboard grab too */
        popup_grab_on_window(gtk_widget_get_window(GTK_WIDGET(real_parent)),
                NULL, self->pointer, time);
}

static gboolean focus_lose(GtkWidget *widget,
                           GdkEvent *event,
                           gpointer userdata)
{
        BudgiePopover *self;

        self = BUDGIE_POPOVER(userdata);

        if (event->type != GDK_KEY_PRESS || event->key.keyval == GDK_KEY_Escape) {
                g_signal_handler_block(self, self->focus_id);
                budgie_popover_hide(self);
                g_signal_handler_unblock(self, self->focus_id);
                return TRUE;
        }
        return FALSE;
}
