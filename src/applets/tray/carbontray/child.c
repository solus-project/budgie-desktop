/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2020 Budgie Desktop Developers
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This file's contents largely use xfce4-panel as a reference, which is licensed under the terms of the GNU GPL v2.
 * Additional notes were taken from na-tray, the previous system tray for Budgie, which is part of MATE Desktop 
 * and licensed under the terms of the GNU GPL v2.
 */

#include "child.h"
#include "tray.h"

// static method header

static void carbon_child_init(CarbonChild*);
static void carbon_child_realize(GtkWidget*);
static void carbon_child_get_preferred_width(GtkWidget*, int*, int*);
static void carbon_child_get_preferred_height(GtkWidget*, int*, int*);
static void set_wmclass(CarbonChild*, Display*);



// define our type with the macro

G_DEFINE_TYPE(CarbonChild, carbon_child, GTK_TYPE_SOCKET)



// public method implementations

CarbonChild* carbon_child_new(int size, GdkScreen *screen, Window iconWindow) {
	if (GDK_IS_SCREEN(screen) == FALSE) {
		g_warning("No screen to place tray icon onto");
		return NULL;
	}

	if (iconWindow == None) {
		g_warning("No icon window to add to tray");
		return NULL;
	}

	GdkDisplay *display = gdk_screen_get_display(screen);
	Display *xdisplay = GDK_DISPLAY_XDISPLAY(display);

	gdk_x11_display_error_trap_push(display);
	XWindowAttributes attributes;
	int result = XGetWindowAttributes(xdisplay, iconWindow, &attributes);
	int error = gdk_x11_display_error_trap_pop(display);

	if (result == 0) {
		g_warning("Failed to get icon window attributes");
		return NULL;
	}

	if (error != 0) {
		g_warning("Encountered X error %d when obtaining window attributes for tray icon", error);
		return NULL;
	}

	GdkVisual *visual = gdk_x11_screen_lookup_visual(screen, attributes.visual->visualid);
	if (visual == NULL || GDK_IS_VISUAL(visual) == FALSE)
		return NULL;

	CarbonChild *self = g_object_new(CARBON_TYPE_CHILD, NULL);
    self->preferredWidth = size;
	self->preferredHeight = size;
	self->iconWindow = iconWindow;
	self->isComposited = FALSE;
	gtk_widget_set_visual(GTK_WIDGET(self), visual);

	/* check if there is an alpha channel in the visual */
	int red_prec, green_prec, blue_prec;
	gdk_visual_get_red_pixel_details(visual, NULL, NULL, &red_prec);
	gdk_visual_get_green_pixel_details(visual, NULL, NULL, &green_prec);
	gdk_visual_get_blue_pixel_details(visual, NULL, NULL, &blue_prec);

	bool supportsComposite = gdk_display_supports_composite(display);
	if (red_prec + blue_prec + green_prec < gdk_visual_get_depth(visual) && supportsComposite)
		self->isComposited = TRUE;

	self->wmclass = NULL;
	set_wmclass(self, xdisplay);

  	return self;
}

void carbon_child_draw_on_tray(CarbonChild *self, GtkWidget *parent, cairo_t *cr) {
	g_return_if_fail(self != NULL);
	g_return_if_fail(parent != NULL);
	g_return_if_fail(cr != NULL);

    GtkAllocation allocation = {0};
	gtk_widget_get_allocation(GTK_WIDGET(self), &allocation);

	if (!gtk_widget_get_has_window(GTK_WIDGET(parent))) {
		GtkAllocation parentAllocation = {0};
		gtk_widget_get_allocation(GTK_WIDGET(parent), &parentAllocation);

		allocation.x = allocation.x - parentAllocation.x;
		allocation.y = allocation.y - parentAllocation.y;
	}
	cairo_save(cr);
	GdkWindow *window = gtk_widget_get_window(GTK_WIDGET(self));
	gdk_cairo_set_source_window(cr, window, allocation.x, allocation.y);
	cairo_rectangle(cr, allocation.x, allocation.y, allocation.width, allocation.height);
	cairo_clip(cr);
	cairo_paint(cr);
	cairo_restore(cr);
}



// static method implementations

static void carbon_child_init(CarbonChild *self) {
    GtkWidget *widget = GTK_WIDGET(self);

	gtk_widget_set_halign(widget, GTK_ALIGN_CENTER);
	gtk_widget_set_valign(widget, GTK_ALIGN_CENTER);
	gtk_widget_set_hexpand(widget, FALSE);
	gtk_widget_set_vexpand(widget, FALSE);
}

static void carbon_child_realize(GtkWidget *widget) {
	CarbonChild *self = CARBON_CHILD(widget);

	gtk_widget_set_size_request(widget, self->preferredWidth, self->preferredHeight);
	GTK_WIDGET_CLASS(carbon_child_parent_class)->realize(widget);

	GdkWindow *window = gtk_widget_get_window(widget);

	if (self->isComposited) {
		GdkRGBA transparent;
		gdk_window_set_background_rgba(window, &transparent);
	} else if (gtk_widget_get_visual(widget) == gdk_window_get_visual(gdk_window_get_parent(window))) {
		gdk_window_set_background_pattern(window, NULL);
	} else {
		self->parentRelativeBg = FALSE;
	}

	gdk_window_set_composited(window, self->isComposited);
	gtk_widget_set_app_paintable(widget, self->parentRelativeBg || self->isComposited);
}

static void carbon_child_get_preferred_width(GtkWidget *base, int *minimum_width, int *natural_width) {
	CarbonChild *self = CARBON_CHILD(base);
    int scale = gtk_widget_get_scale_factor(base);

    *minimum_width = self->preferredWidth / scale;
    *natural_width = self->preferredWidth / scale;
}

static void carbon_child_get_preferred_height(GtkWidget *base, int *minimum_height, int *natural_height) {
	CarbonChild *self = CARBON_CHILD(base);
    int scale = gtk_widget_get_scale_factor(base);

    *minimum_height = self->preferredHeight / scale;
    *natural_height = self->preferredHeight / scale;
}

static void carbon_child_class_init(CarbonChildClass *klass) {
    GtkWidgetClass *gtkwidget_class = GTK_WIDGET_CLASS(klass);

	gtkwidget_class->get_preferred_width = carbon_child_get_preferred_width;
	gtkwidget_class->get_preferred_height = carbon_child_get_preferred_height;
    gtkwidget_class->realize = carbon_child_realize;
}

static void set_wmclass(CarbonChild *self, Display *xdisplay) {
	XClassHint ch;
	ch.res_class = NULL;

	GdkDisplay *display = gdk_display_get_default();
	gdk_x11_display_error_trap_push(display);
	XGetClassHint(xdisplay, self->iconWindow, &ch);
	gdk_x11_display_error_trap_pop_ignored(display);

	if (ch.res_class) {
		self->wmclass = ch.res_class;
	}
}
