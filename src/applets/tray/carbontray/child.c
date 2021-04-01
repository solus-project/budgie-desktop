/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2021 Budgie Desktop Developers
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

static void carbon_child_init(CarbonChild* child);
static void carbon_child_get_preferred_size(GtkWidget* parent, int* minimumSize, int* naturalSize);
static bool set_wmclass(CarbonChild* self, GdkDisplay* display, Display* xdisplay);
static void synchronized_display_error_trap_push(GdkDisplay* display);
static bool synchronized_display_error_trap_pop(GdkDisplay* display);


// define our type with the macro

G_DEFINE_TYPE(CarbonChild, carbon_child, GTK_TYPE_SOCKET)


// public method implementations

CarbonChild* carbon_child_new(int size, bool shouldComposite, GdkScreen* screen, Window iconWindow) {
	if (!GDK_IS_SCREEN(screen)) {
		g_warning("No screen to place tray icon onto");
		return NULL;
	}

	if (iconWindow == None) {
		g_warning("No icon window to add to tray");
		return NULL;
	}

	GdkDisplay* display = gdk_screen_get_display(screen);
	Display* xdisplay = GDK_DISPLAY_XDISPLAY(display);

	synchronized_display_error_trap_push(display);
	XWindowAttributes attributes;
	int result = XGetWindowAttributes(xdisplay, iconWindow, &attributes);
	int error = synchronized_display_error_trap_pop(display);

	if (result == 0) {
		g_info("Failed to populate icon window attributes for tray icon");
		return NULL;
	}

	if (error != 0) {
		g_warning("Encountered X error %d when obtaining window attributes for tray icon", error);
		return NULL;
	}

	GdkVisual* visual = gdk_x11_screen_lookup_visual(screen, attributes.visual->visualid);
	if (visual == NULL || !GDK_IS_VISUAL(visual)) {
		return NULL;
	}

	CarbonChild* self = g_object_new(CARBON_TYPE_CHILD, NULL);
	self->preferredSize = size;
	self->iconWindow = iconWindow;
	self->hasAlpha = false;
	self->parentRelativeBg = false;
	self->wmclass = NULL;

	gtk_widget_set_visual(GTK_WIDGET(self), visual);

	if (shouldComposite) {
		// check if there is an alpha channel in the visual. if there is, we can composite it
		int red_prec, green_prec, blue_prec;
		gdk_visual_get_red_pixel_details(visual, NULL, NULL, &red_prec);
		gdk_visual_get_green_pixel_details(visual, NULL, NULL, &green_prec);
		gdk_visual_get_blue_pixel_details(visual, NULL, NULL, &blue_prec);

		if (red_prec + blue_prec + green_prec < gdk_visual_get_depth(visual)) {
			self->hasAlpha = true;
		}
	}

	if (!set_wmclass(self, display, xdisplay)) {
		// the icon window turned sour while we were getting alpha details. ignore the child
		return NULL;
	}

	return self;
}

bool carbon_child_realize(CarbonChild* self) {
	GtkWidget* widget = GTK_WIDGET(self);
	self->widgetWindow = gtk_widget_get_window(widget);

	GdkDisplay* display = gtk_widget_get_display(widget);

	// make X calls synchronous for background setting, so that BadWindow errors can be caught
	synchronized_display_error_trap_push(display);

	Display* xdisplay = GDK_DISPLAY_XDISPLAY(display);
	if (self->hasAlpha) {
		XSetWindowBackground(xdisplay, self->iconWindow, 0);
	} else if (gtk_widget_get_visual(widget) == gdk_window_get_visual(gdk_window_get_parent(self->widgetWindow))) {
		XSetWindowBackgroundPixmap(xdisplay, self->iconWindow, None);
		self->parentRelativeBg = true;
	}

	// make X calls asynchronous again, all errors have already been trapped
	int error = synchronized_display_error_trap_pop(display);

	if (error != 0) {
		g_warning("Encountered X error %d when setting background for tray icon", error);
		return false;
	}

	gdk_window_set_composited(self->widgetWindow, self->hasAlpha);
	gtk_widget_set_app_paintable(widget, self->parentRelativeBg || self->hasAlpha);
	gtk_widget_set_size_request(widget, self->preferredSize, self->preferredSize);
	return true;
}

void carbon_child_draw_on_tray(CarbonChild* self, GtkWidget* parent, cairo_t* cr) {
	g_return_if_fail(self != NULL);
	g_return_if_fail(parent != NULL);
	g_return_if_fail(cr != NULL);

	GtkAllocation allocation;
	gtk_widget_get_allocation(GTK_WIDGET(self), &allocation);

	if (!gtk_widget_get_has_window(parent)) {
		GtkAllocation parentAllocation;
		gtk_widget_get_allocation(parent, &parentAllocation);

		allocation.x = allocation.x - parentAllocation.x;
		allocation.y = allocation.y - parentAllocation.y;
	}
	cairo_save(cr);

	gdk_cairo_set_source_window(cr, self->widgetWindow, allocation.x, allocation.y);
	cairo_rectangle(cr, allocation.x, allocation.y, allocation.width, allocation.height);
	cairo_clip(cr);
	cairo_paint(cr);
	cairo_restore(cr);
}



// static method implementations

static void carbon_child_init(CarbonChild* self) {
	GtkWidget* widget = GTK_WIDGET(self);
	gtk_widget_set_halign(widget, GTK_ALIGN_CENTER);
	gtk_widget_set_valign(widget, GTK_ALIGN_CENTER);
}

static void carbon_child_get_preferred_size(GtkWidget* base, int* minimum_size, int* natural_size) {
	int preferredSize = CARBON_CHILD(base)->preferredSize;
	*minimum_size = preferredSize;
	*natural_size = preferredSize;
}

static void carbon_child_class_init(CarbonChildClass* klass) {
	GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);

	widget_class->get_preferred_width = carbon_child_get_preferred_size;
	widget_class->get_preferred_height = carbon_child_get_preferred_size;
}

static bool set_wmclass(CarbonChild* self, GdkDisplay* display, Display* xdisplay) {
	XClassHint ch = {0};

	synchronized_display_error_trap_push(display);
	XGetClassHint(xdisplay, self->iconWindow, &ch);
	int error = synchronized_display_error_trap_pop(display);

	if (error != 0) {
		g_warning("Encountered X error %d when obtaining class hint for tray icon", error);
		return false;
	}

	if (ch.res_name != NULL) XFree(ch.res_name);
	if (ch.res_class != NULL) self->wmclass = ch.res_class;

	return true;
}

static void synchronized_display_error_trap_push(GdkDisplay* display) {
	gdk_x11_display_error_trap_push(display);
	XSynchronize(GDK_DISPLAY_XDISPLAY(display), true);
}

static bool synchronized_display_error_trap_pop(GdkDisplay* display) {
	XSynchronize(GDK_DISPLAY_XDISPLAY(display), false);
	return gdk_x11_display_error_trap_pop(display);
}
