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
                             gdouble tail_height);

/* Initialisation */
static void budgie_popover_class_init(BudgiePopoverClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_popover_dispose;
}


static void budgie_popover_init(BudgiePopover *self)
{
        GtkWidget *empty = NULL;

        /* We don't override as we need some GtkWindow rendering */
        g_signal_connect(self, "draw", G_CALLBACK(budgie_popover_draw), self);

        empty = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 1);
        gtk_window_set_titlebar(GTK_WINDOW(self), empty);

        /* Skip, no decorations, etc */
        gtk_window_set_skip_taskbar_hint(GTK_WINDOW(self), TRUE);
        gtk_window_set_skip_pager_hint(GTK_WINDOW(self), TRUE);

        gtk_widget_realize(GTK_WIDGET(self));
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

static gboolean budgie_popover_draw(GtkWidget *widget,
                                    cairo_t *cr,
                                    gboolean draw)
{
        GtkStyleContext *style;
        GtkAllocation alloc;
        GtkPositionType gap_side;
        GdkRGBA color;
        gdouble x, y, tail_height, gap_width;
        gdouble margin, width, height, gap1, gap2;

        x = 0;
        y = 0;
        tail_height = 12;
        gap_width = 24;
        margin = 11;

        x += margin;
        y += margin;

        style = gtk_widget_get_style_context(widget);
        gtk_style_context_add_class(style, GTK_STYLE_CLASS_FRAME);

        gtk_widget_get_allocation(widget, &alloc);
        /* Have parent class do drawing, so we gain shadows */
        ((GtkWidgetClass*)budgie_popover_parent_class)->draw(widget, cr);

        /* Remove height of tail, and margin, from our rendered size */
        width = alloc.width;
        height = alloc.height - tail_height;
        height -= margin;
        width -= margin*2;

        cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
        gap1 = (alloc.width/2)-(gap_width/2);
        gap2 = gap1 + gap_width;
        gap2 -= margin;
        gap_side = GTK_POS_BOTTOM;

        /* Render a gap in the bottom center for our arrow */
        gtk_render_frame_gap(style, cr, x, y, width, height,
                gap_side, gap1, gap2);
        /* Fill in the background (pre-clip) */
        gtk_render_background(style, cr, x, y, width, height);

        /* Clip to the tail, fill in the arrow background */
        cairo_save(cr);
        budgie_tail_path(cr, gap1, gap_width, height+margin, tail_height);
        cairo_clip(cr);
        gtk_render_background(style, cr, x, y, alloc.width, alloc.height);
        cairo_restore(cr);

        /* Draw in the border */
        gtk_style_context_get_border_color(style, gtk_widget_get_state_flags(widget), &color);
        gdk_cairo_set_source_rgba(cr, &color);
        cairo_set_line_width(cr, 1);
        budgie_tail_path(cr, gap1, gap_width, height+margin, tail_height);
        cairo_stroke(cr);

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
                             gdouble tail_height)
{
        gdouble start_x = gap1;
        gdouble end_x = gap1 + gap_width;
        gdouble start_y = height-1;
        gdouble end_y = start_y;
        gdouble tip_x = start_x + (gap_width/2);
        gdouble tip_y = start_y + tail_height;

        /* Draw a triangle, basically */
        cairo_move_to(cr, start_x, start_y);
        cairo_line_to(cr, tip_x, tip_y);
        cairo_line_to(cr, end_x, end_y);
}

void budgie_popover_present(BudgiePopover *self,
                            GtkWidget *parent)
{
        GtkWidget *real_parent;
        GdkWindow *parent_window;
        GtkAllocation alloc, our_alloc;
        gint x, y, tx, ty;

        /* Get position of parent widget on screen */
        real_parent = gtk_widget_get_toplevel(parent);
        parent_window = gtk_widget_get_window(real_parent);
        gdk_window_get_position(parent_window, &x, &y);
        gtk_widget_translate_coordinates(parent, real_parent, x, y, &tx, &ty);

        /* And subtract parent widget height */
        gtk_widget_get_allocation(parent, &alloc);
        gtk_widget_get_allocation(GTK_WIDGET(self), &our_alloc);
        ty -= alloc.height;
        ty -= our_alloc.height;

        gtk_window_move(GTK_WINDOW(self), tx, ty);
        gtk_widget_show_all(GTK_WIDGET(self));
}
