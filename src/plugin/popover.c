/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#define _GNU_SOURCE

#include "util.h"

BUDGIE_BEGIN_PEDANTIC
#include "budgie-enums.h"
#include "popover.h"
#include <gtk/gtk.h>
BUDGIE_END_PEDANTIC

/**
 * SECTION:popover
 * @Short_description: Budgie Panel GTK+ Popover Widget
 * @Title: BudgiePopover
 *
 * The BudgiePopover is a specialised top level window with a tail pointer,
 * providing a decorative approach to panel windows. These windows point
 * at the source of an event, such as a button, and allow rich user interfaces
 * to be built with a focus on Budgie Panel usage.
 *
 * The BudgiePopover should be used in conjunction with the #BudgiePopoverManager.
 * Simply add your content to the popover, and ensure that you call
 * #GtkWidget:show_all to display the contents.
 *
 * Your popover may be dismissed from screen in response to an event, such
 * as the user pressing the button again, or automatically, as the user
 * clicked outside of the window, or even because the #BudgiePopoverManager
 * switched to a new active popover. You may connect to the #BudgiePopover::closed
 * signal to check for this event.
 *
 */

/*
 * We'll likely take this from a style property in future, but for now it
 * is both the width and height of a tail
 */
#define TAIL_DIMENSION 16
#define TAIL_HEIGHT TAIL_DIMENSION / 2
#define SHADOW_DIMENSION 4
#define BORDER_WIDTH 1

/*
 * Used for storing BudgieTail calculations
 */
typedef struct BudgieTail {
	double start_x;
	double start_y;
	double end_x;
	double end_y;
	double x;
	double y;
	double x_offset;
	double y_offset;
	GtkPositionType position;
} BudgieTail;

struct _BudgiePopoverPrivate {
	GtkWidget* add_area;
	GtkWidget* relative_to;
	BudgieTail tail;
	GdkRectangle widget_rect;
	BudgiePopoverPositionPolicy policy;
};

enum {
	PROP_RELATIVE_TO = 1,
	PROP_POLICY,
	N_PROPS
};

static GParamSpec* obj_properties[N_PROPS] = {
	NULL,
};

/*
 * IDs for our signals
 */
enum {
	POPOVER_SIGNAL_CLOSED = 0,
	N_SIGNALS
};

static guint popover_signals[N_SIGNALS] = {0};

G_DEFINE_TYPE_WITH_PRIVATE(BudgiePopover, budgie_popover, GTK_TYPE_WINDOW)

static gboolean budgie_popover_draw(GtkWidget* widget, cairo_t* cr);
static void budgie_popover_map(GtkWidget* widget);
static void budgie_popover_unmap(GtkWidget* widget);
static void budgie_popover_size_allocate(GtkWidget* widget, GdkRectangle* rectangle, gpointer udata);
static void budgie_popover_add(GtkContainer* container, GtkWidget* widget);
static gboolean budgie_popover_button_press(GtkWidget* widget, GdkEventButton* button, gpointer udata);
static gboolean budgie_popover_key_press(GtkWidget* widget, GdkEventKey* key, gpointer udata);
static void budgie_popover_set_property(GObject* object, guint id, const GValue* value, GParamSpec* spec);
static void budgie_popover_get_property(GObject* object, guint id, GValue* value, GParamSpec* spec);
static void budgie_popover_compute_positition(BudgiePopover* self, GdkRectangle* target);
static void budgie_popover_compute_widget_geometry(BudgiePopover* self);
static void budgie_popover_compute_tail(BudgiePopover* self);
static void budgie_popover_update_position_hints(BudgiePopover* self);
static void budgie_popover_get_screen_for_widget(GtkWidget* widget, GdkRectangle* rectangle);

/**
 * budgie_popover_dispose:
 *
 * Clean up a BudgiePopover instance
 */
static void budgie_popover_dispose(GObject* obj) {
	G_OBJECT_CLASS(budgie_popover_parent_class)->dispose(obj);
}

/**
 * budgie_popover_constructor:
 *
 * Override initial properties to be sane
 *
 * Influence:
 * https://stackoverflow.com/questions/16557905/change-g-param-construct-only-property-via-inheritance
 */
static GObject* budgie_popover_constructor(GType type, guint n_properties, GObjectConstructParam* properties) {
	GObject* o = NULL;
	const gchar* prop_name = NULL;
	GObjectConstructParam* param = NULL;

	/* Override the construct-only type property */
	for (guint i = 0; i < n_properties; i++) {
		param = &properties[i];

		prop_name = g_param_spec_get_name(param->pspec);
		if (g_str_equal(prop_name, "type")) {
			g_value_set_enum(param->value, GTK_WINDOW_POPUP);
		}
	}

	o = G_OBJECT_CLASS(budgie_popover_parent_class)->constructor(type, n_properties, properties);

	/* Blame clang-format for weird wrapping */
	g_object_set(
		o,
		"app-paintable", TRUE,
		"decorated", FALSE,
		"deletable", FALSE,
		"focus-on-map", TRUE,
		"gravity", GDK_GRAVITY_NORTH_WEST,
		"modal", FALSE,
		"resizable", FALSE,
		"skip-pager-hint", TRUE,
		"skip-taskbar-hint", TRUE,
		"type-hint", GDK_WINDOW_TYPE_HINT_POPUP_MENU,
		"window-position", GTK_WIN_POS_NONE,
		NULL);

	return o;
}

/**
 * budgie_popover_class_init:
 *
 * Handle class initialisation
 */
static void budgie_popover_class_init(BudgiePopoverClass* klazz) {
	GObjectClass* obj_class = G_OBJECT_CLASS(klazz);
	GtkWidgetClass* wid_class = GTK_WIDGET_CLASS(klazz);
	GtkContainerClass* cont_class = GTK_CONTAINER_CLASS(klazz);

	/* gobject vtable hookup */
	obj_class->constructor = budgie_popover_constructor;
	obj_class->dispose = budgie_popover_dispose;
	obj_class->set_property = budgie_popover_set_property;
	obj_class->get_property = budgie_popover_get_property;

	/* widget vtable hookup */
	wid_class->draw = budgie_popover_draw;
	wid_class->map = budgie_popover_map;
	wid_class->unmap = budgie_popover_unmap;

	/* container vtable */
	cont_class->add = budgie_popover_add;

	/**
	 * BudgiePopover::closed
	 * @popover: The popover that has been closed
	 *
	 * This signal is emitted when the popover has been dismissed, whether
	 * it was deliberately from the user's perspective, or implicitly
	 * through a toggling action, such as being rolled past in a
	 * #BudgiePopoverManager set of popovers.
	 */
	popover_signals[POPOVER_SIGNAL_CLOSED] = g_signal_new(
		"closed",
		BUDGIE_TYPE_POPOVER,
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET(BudgiePopoverClass, closed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

	/*
	 * BudgiePopover:relative-to
	 *
	 * Determines the GtkWidget that we'll appear next to
	 */
	obj_properties[PROP_RELATIVE_TO] = g_param_spec_object(
		"relative-to", "Relative widget", "Set the relative widget",
		GTK_TYPE_WIDGET, G_PARAM_READWRITE);

	/**
	 * BudgiePopover:position-policy:
	 *
	 * Control the behavior used to place the popover on screen.
	 */
	obj_properties[PROP_POLICY] = g_param_spec_enum(
		"position-policy", "Positioning policy", "Get/set the popover position policy",
		BUDGIE_TYPE_POPOVER_POSITION_POLICY, BUDGIE_POPOVER_POSITION_AUTOMATIC, G_PARAM_READWRITE);

	g_object_class_install_properties(obj_class, N_PROPS, obj_properties);
}

/**
 * budgie_popover_init:
 *
 * Handle construction of the BudgiePopover
 */
static void budgie_popover_init(BudgiePopover* self) {
	GtkWindow* win = GTK_WINDOW(self);
	GdkScreen* screen = NULL;
	GdkVisual* visual = NULL;
	GtkStyleContext* style = NULL;

	self->priv = budgie_popover_get_instance_private(self);

	style = gtk_widget_get_style_context(GTK_WIDGET(self));
	gtk_style_context_add_class(style, "budgie-popover");

	/* Allow budgie-wm to know what we are */
	G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	gtk_window_set_wmclass(GTK_WINDOW(self), "budgie-popover", "budgie-popover");
	G_GNUC_END_IGNORE_DEPRECATIONS

	self->priv->add_area = gtk_frame_new(NULL);
	style = gtk_widget_get_style_context(GTK_WIDGET(self->priv->add_area));
	gtk_style_context_add_class(style, "container");
	gtk_container_add(GTK_CONTAINER(self), self->priv->add_area);
	gtk_widget_show_all(self->priv->add_area);

	/* Setup window specific bits */
	gtk_window_set_position(win, GTK_WIN_POS_CENTER);
	g_signal_connect(win, "button-press-event", G_CALLBACK(budgie_popover_button_press), NULL);
	g_signal_connect(win, "key-press-event", G_CALLBACK(budgie_popover_key_press), NULL);
	g_signal_connect_after(win, "size-allocate", G_CALLBACK(budgie_popover_size_allocate), NULL);

	/* Set up RGBA ability */
	screen = gtk_widget_get_screen(GTK_WIDGET(self));
	visual = gdk_screen_get_rgba_visual(screen);
	if (visual) {
		gtk_widget_set_visual(GTK_WIDGET(self), visual);
	}
	/* We do all rendering */
	gtk_widget_set_app_paintable(GTK_WIDGET(self), TRUE);

	/* Set initial placement up for default bottom position */
	self->priv->tail.position = GTK_POS_BOTTOM;

	budgie_popover_update_position_hints(self);
}

static void budgie_popover_map(GtkWidget* widget) {
	GdkWindow* window = NULL;
	GdkRectangle coords = {0};
	BudgiePopover* self = NULL;

	self = BUDGIE_POPOVER(widget);

	/* Determine our relative-to widget's location on screen */
	budgie_popover_compute_widget_geometry(self);

	/* Work out where we go on screen now */
	budgie_popover_compute_positition(self, &coords);

	/* Forcibly request focus */
	window = gtk_widget_get_window(widget);
	gdk_window_set_accept_focus(window, TRUE);
	gdk_window_focus(window, GDK_CURRENT_TIME);
	gdk_window_move(window, coords.x, coords.y);
	gtk_window_present(GTK_WINDOW(widget));

	GTK_WIDGET_CLASS(budgie_popover_parent_class)->map(widget);
}

/**
 * budgie_popover_trigger_closed:
 *
 * Used to emit the `closed` signal on the idle loop, after we've dealt
 * with the unmap event cleanly.
 */
static inline gboolean budgie_popover_trigger_closed(gpointer v) {
	g_signal_emit(v, popover_signals[POPOVER_SIGNAL_CLOSED], 0);
	return G_SOURCE_REMOVE;
}

static void budgie_popover_unmap(GtkWidget* widget) {
	GTK_WIDGET_CLASS(budgie_popover_parent_class)->unmap(widget);
	g_idle_add(budgie_popover_trigger_closed, widget);
}

/**
 * budgie_popover_size_allocate:
 *
 * Upon having our contents resize us, i.e. a #GtkStack or #GtkRevealer, we
 * re-calculate our position to ensure we resize in the right direction.
 */
static void budgie_popover_size_allocate(GtkWidget* widget, __budgie_unused__ GdkRectangle* rectangle, __budgie_unused__ gpointer udata) {
	GdkRectangle coords = {0};
	BudgiePopover* self = NULL;
	GdkWindow* window = NULL;

	if (!gtk_widget_get_realized(widget)) {
		return;
	}

	self = BUDGIE_POPOVER(widget);

	window = gtk_widget_get_window(widget);

	/* Work out where we go on screen now */
	budgie_popover_compute_positition(self, &coords);
	gdk_window_move(window, coords.x, coords.y);
	gtk_widget_queue_draw(widget);
}

/**
 * budgie_popover_select_position_toplevel:
 *
 * Select the position of the popover tail (and extend outwards from it)
 * based on the hints provided by the toplevel
 */
static GtkPositionType budgie_popover_select_position_toplevel(BudgiePopover* self) {
	GtkWidget* parent_window = NULL;

	/* Tail points out from the panel */
	parent_window = gtk_widget_get_toplevel(self->priv->relative_to);
	if (!parent_window) {
		return GTK_POS_BOTTOM;
	}

	GtkStyleContext* context = gtk_widget_get_style_context(parent_window);
	if (gtk_style_context_has_class(context, "top")) {
		return GTK_POS_TOP;
	} else if (gtk_style_context_has_class(context, "left")) {
		return GTK_POS_LEFT;
	} else if (gtk_style_context_has_class(context, "right")) {
		return GTK_POS_RIGHT;
	}

	return GTK_POS_BOTTOM;
}

/**
 * budgie_popover_select_position_automatic:
 *
 * Select the position based on the amount of space available in the given
 * regions.
 *
 * Typically we'll always try to display underneath first, and failing that
 * we'll try to appear above.  If we're still estate-limited, we'll then try
 * the right hand side, before finally falling back to the left hand side for display.
 *
 * The side options will also utilise Y-offsets and bounding to ensure there
 * is always some way to fit the popover sanely on screen.
 */
static GtkPositionType budgie_popover_select_position_automatic(gint our_height, GdkRectangle screen_rect, GdkRectangle widget_rect) {
	/* Try to show the popover underneath */
	if (widget_rect.y + widget_rect.height + TAIL_HEIGHT + SHADOW_DIMENSION + our_height <=
		screen_rect.y + screen_rect.height) {
		return GTK_POS_TOP;
	}

	/* Now try to show the popover above the widget */
	if (widget_rect.y - TAIL_HEIGHT - SHADOW_DIMENSION - our_height >= screen_rect.y) {
		return GTK_POS_BOTTOM;
	}

	/* Work out which has more room, left or right. */
	double room_right = screen_rect.x + screen_rect.width - (widget_rect.x + widget_rect.width);
	double room_left = widget_rect.x - screen_rect.x;

	if (room_left > room_right) {
		return GTK_POS_RIGHT;
	}

	return GTK_POS_LEFT;
}

/**
 * budgie_popover_update_position_hints:
 *
 * Update our style classes and padding in response to a tail change
 */
static void budgie_popover_update_position_hints(BudgiePopover* self) {
	GtkStyleContext* style = NULL;
	const gchar* style_class = NULL;
	static const gchar* position_classes[] = {"top", "left", "right", "bottom"};

	/* Allow themers to know what kind of popover this is, and set the
	 * CSS class in accordance with the direction that the popover is
	 * pointing in.
	 */
	style = gtk_widget_get_style_context(GTK_WIDGET(self));
	for (guint i = 0; i < G_N_ELEMENTS(position_classes); i++) {
		gtk_style_context_remove_class(style, position_classes[i]);
	}

	switch (self->priv->tail.position) {
		case GTK_POS_BOTTOM:
			g_object_set(
				self->priv->add_area,
				"margin-top", 5,
				"margin-bottom", 13,
				"margin-start", 5,
				"margin-end", 5,
				NULL);
			style_class = "bottom";
			break;
		case GTK_POS_TOP:
			g_object_set(
				self->priv->add_area,
				"margin-top", 9,
				"margin-bottom", 9,
				"margin-start", 5,
				"margin-end", 5,
				NULL);
			style_class = "top";
			break;
		case GTK_POS_LEFT:
			g_object_set(
				self->priv->add_area,
				"margin-top", 5,
				"margin-bottom", 9,
				"margin-start", 13,
				"margin-end", 5,
				NULL);
			style_class = "left";
			break;
		case GTK_POS_RIGHT:
			g_object_set(
				self->priv->add_area,
				"margin-top", 5,
				"margin-bottom", 9,
				"margin-start", 5,
				"margin-end", 13,
				NULL);
			style_class = "right";
			break;
		default:
			break;
	}

	gtk_style_context_add_class(style, style_class);
}

/**
 * budgie_popover_compute_geometry:
 *
 * Work out the geometry for the relative_to widget in absolute coordinates
 * on the screen.
 */
static void budgie_popover_compute_widget_geometry(BudgiePopover* self) {
	GtkAllocation alloc = {0};
	GtkWidget* toplevel = NULL;
	gint rx, ry = 0;
	gint x, y = 0;
	GdkRectangle display_geom = {0};
	gint our_height = 0, our_width = 0;
	GtkPositionType tail_position = GTK_POS_TOP;

	if (!self->priv->relative_to) {
		g_warning("compute_widget_geometry(): missing relative_widget");
		return;
	}

	budgie_popover_get_screen_for_widget(self->priv->relative_to, &display_geom);
	gtk_window_get_size(GTK_WINDOW(self), &our_width, &our_height);

	toplevel = gtk_widget_get_toplevel(self->priv->relative_to);
	gtk_window_get_position(GTK_WINDOW(toplevel), &x, &y);
	gtk_widget_translate_coordinates(self->priv->relative_to, toplevel, x, y, &rx, &ry);
	gtk_widget_get_allocation(self->priv->relative_to, &alloc);

	self->priv->widget_rect = (GdkRectangle){.x = rx, .y = ry, .width = alloc.width, .height = alloc.height};

	/* Determine our position now based on the widget's geometry and our own */
	if (self->priv->policy == BUDGIE_POPOVER_POSITION_TOPLEVEL_HINT) {
		tail_position = budgie_popover_select_position_toplevel(self);
	} else {
		tail_position = budgie_popover_select_position_automatic(our_height, display_geom, self->priv->widget_rect);
	}

	/* Don't do this unless something changed */
	if (self->priv->tail.position != tail_position) {
		self->priv->tail.position = tail_position;
		budgie_popover_update_position_hints(self);
	}

	/* Update tail knowledge */
	self->priv->tail.position = tail_position;
	budgie_popover_compute_tail(self);
}

/**
 * budgie_popover_get_screen_for_widget:
 *
 * Use the appropriate function to find out the monitor's resolution for the
 * given @widget.
 */
static void budgie_popover_get_screen_for_widget(GtkWidget* widget, GdkRectangle* rectangle) {
	GdkScreen* screen = NULL;
	GdkWindow* assoc_window = NULL;
	GdkDisplay* display = NULL;

	assoc_window = gtk_widget_get_parent_window(widget);
	screen = gtk_widget_get_screen(widget);
	display = gdk_screen_get_display(screen);

#if GTK_CHECK_VERSION(3, 22, 0)
	GdkMonitor* monitor = gdk_display_get_monitor_at_window(display, assoc_window);
	gdk_monitor_get_geometry(monitor, rectangle);
#else
	gint monitor = gdk_screen_get_monitor_at_window(screen, assoc_window);
	gdk_screen_get_monitor_geometry(screen, monitor, rectangle);
#endif
}

/**
 * budgie_popover_compute_position:
 *
 * Work out exactly where the popover needs to appear on screen
 *
 * This will try to account for all potential positions, using a fairly
 * biased view of what the popover should do in each situation.
 *
 * Unlike a typical popover implementation, this relies on some information
 * from the toplevel window on what edge it happens to be on.
 */
static void budgie_popover_compute_positition(BudgiePopover* self, GdkRectangle* target) {
	GtkPositionType tail_position = GTK_POS_BOTTOM;
	gint our_width = 0, our_height = 0;
	int x = 0, y = 0, width = 0, height = 0;
	GdkRectangle display_geom = {0};
	GdkRectangle widget_rect = {0};

	/* Work out our own size */
	gtk_window_get_size(GTK_WINDOW(self), &our_width, &our_height);

	/* Work out the real screen geometry involved here */
	budgie_popover_get_screen_for_widget(self->priv->relative_to, &display_geom);

	tail_position = self->priv->tail.position;
	budgie_popover_compute_tail(self);
	widget_rect = self->priv->widget_rect;

	/* Now work out where we live on screen */
	switch (tail_position) {
		case GTK_POS_BOTTOM:
			/* We need to appear above the widget */
			y = widget_rect.y - our_height;
			x = (widget_rect.x + (widget_rect.width / 2)) - (our_width / 2);
			break;
		case GTK_POS_TOP:
			/* We need to appear below the widget */
			y = widget_rect.y + widget_rect.height + (TAIL_DIMENSION / 2);
			x = (widget_rect.x + (widget_rect.width / 2)) - (our_width / 2);
			break;
		case GTK_POS_LEFT:
			/* We need to appear to the right of the widget */
			y = (widget_rect.y + (widget_rect.height / 2)) - (our_height / 2);
			x = widget_rect.x + widget_rect.width;
			break;
		case GTK_POS_RIGHT:
			y = (widget_rect.y + (widget_rect.height / 2)) - (our_height / 2);
			x = widget_rect.x - our_width;
			break;
		default:
			break;
	}

	static int pad_num = 1;

	/* Bound X to display width */
	if (x < display_geom.x) {
		self->priv->tail.x_offset += (x - (display_geom.x + pad_num));
		x -= (int) (self->priv->tail.x_offset);
	} else if ((x + our_width) >= display_geom.x + display_geom.width) {
		self->priv->tail.x_offset -= ((display_geom.x + display_geom.width) - (our_width + pad_num)) - x;
		x -= (int) (self->priv->tail.x_offset);
	}

	/* Bound Y to display height */
	if (y < display_geom.y) {
		self->priv->tail.y_offset += (y - (display_geom.y + pad_num));
		y -= (int) (self->priv->tail.y_offset);
	} else if ((y + our_height) >= display_geom.y + display_geom.height) {
		self->priv->tail.y_offset -= ((display_geom.y + display_geom.height) - (our_height + pad_num)) - y;
		y -= (int) (self->priv->tail.y_offset);
	}

	double display_tail_x = x + self->priv->tail.x + self->priv->tail.x_offset;
	double display_tail_y = y + self->priv->tail.y + self->priv->tail.y_offset;
	static double required_offset_x = TAIL_DIMENSION * 1.25;
	static double required_offset_y = TAIL_DIMENSION * 1.75;

	/* Prevent the tail pointer spilling outside the X bounds */
	if (display_tail_x <= display_geom.x + required_offset_x) {
		self->priv->tail.x_offset += (display_geom.x + required_offset_x) - display_tail_x;
	} else if (display_tail_x >= ((display_geom.x + display_geom.width) - required_offset_x)) {
		self->priv->tail.x_offset -= (display_tail_x + required_offset_x) - (display_geom.x + display_geom.width);
	}

	/* Prevent the tail pointer spilling outside the Y bounds */
	if (display_tail_y <= display_geom.y + required_offset_y) {
		self->priv->tail.y_offset += (display_geom.y + required_offset_y) - display_tail_y;
	} else if (display_tail_y >= ((display_geom.y + display_geom.height) - required_offset_y)) {
		self->priv->tail.y_offset -= (display_tail_y + required_offset_y) - (display_geom.y + display_geom.height);
	}

	/* Set the target rectangle */
	*target = (GdkRectangle){.x = x, .y = y, .width = width, .height = height};
}

static void budgie_popover_compute_tail(BudgiePopover* self) {
	GtkAllocation alloc = {0};
	BudgieTail t = {0};

	gtk_widget_get_allocation(GTK_WIDGET(self), &alloc);

	t.position = self->priv->tail.position;

	switch (self->priv->tail.position) {
		case GTK_POS_LEFT:
			t.x = alloc.x;
			t.y = alloc.y + (alloc.height / 2);
			t.start_y = t.y - TAIL_HEIGHT;
			t.end_y = t.y + TAIL_HEIGHT;
			t.start_x = t.end_x = t.x + TAIL_HEIGHT + SHADOW_DIMENSION;
			break;
		case GTK_POS_RIGHT:
			t.x = alloc.width;
			t.y = alloc.y + (alloc.height / 2);
			t.start_y = t.y - TAIL_HEIGHT;
			t.end_y = t.y + TAIL_HEIGHT;
			t.start_x = t.end_x = t.x - TAIL_HEIGHT - SHADOW_DIMENSION;
			break;
		case GTK_POS_TOP:
			t.x = (alloc.x + alloc.width / 2);
			t.y = alloc.y + BORDER_WIDTH;
			t.start_x = t.x - TAIL_HEIGHT;
			t.end_x = t.start_x + TAIL_DIMENSION;
			t.start_y = t.y + TAIL_HEIGHT;
			t.end_y = t.start_y;
			break;
		case GTK_POS_BOTTOM:
		default:
			t.x = (alloc.x + alloc.width / 2);
			t.y = (alloc.y + alloc.height) - SHADOW_DIMENSION;
			t.start_x = t.x - TAIL_HEIGHT;
			t.end_x = t.start_x + TAIL_DIMENSION;
			t.start_y = t.y - TAIL_HEIGHT;
			t.end_y = t.start_y;
			break;
	}

	self->priv->tail = t;
}

/**
 * budgie_popover_draw_tail:
 *
 * Draw the popover's tail section.
 */
static void budgie_popover_draw_tail(BudgiePopover* self, cairo_t* cr) {
	BudgieTail* tail = &(self->priv->tail);

	cairo_move_to(cr, tail->start_x + tail->x_offset, tail->start_y + tail->y_offset);
	cairo_line_to(cr, tail->x + tail->x_offset, tail->y + tail->y_offset);
	cairo_line_to(cr, tail->end_x + tail->x_offset, tail->end_y + tail->y_offset);
	cairo_stroke_preserve(cr);
}

/**
 * budgie_popover_draw:
 *
 * Handle the main rendering + clipping of the BudgiePopover
 */
static gboolean budgie_popover_draw(GtkWidget* widget, cairo_t* cr) {
	GtkStyleContext* style = NULL;
	GtkAllocation alloc = {0};
	GdkRGBA border_color = {0};
	GtkBorder border = {0};
	GtkStateFlags fl;
	BudgiePopover* self = NULL;
	GtkAllocation body_alloc = {0};
	GtkWidget* child = NULL;

	self = BUDGIE_POPOVER(widget);

	/* Clear out the background before we draw anything */
	cairo_save(cr);
	cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.0);
	cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
	cairo_paint(cr);
	cairo_restore(cr);

	style = gtk_widget_get_style_context(widget);
	gtk_widget_get_allocation(widget, &alloc);
	body_alloc = alloc;

	body_alloc.x += SHADOW_DIMENSION;
	body_alloc.width -= SHADOW_DIMENSION * 2;
	body_alloc.y += SHADOW_DIMENSION;
	body_alloc.height -= SHADOW_DIMENSION * 2;

	switch (self->priv->tail.position) {
		case GTK_POS_LEFT:
			body_alloc.height -= SHADOW_DIMENSION;
			body_alloc.width -= TAIL_HEIGHT;
			body_alloc.x += TAIL_HEIGHT;
			break;
		case GTK_POS_RIGHT:
			body_alloc.height -= SHADOW_DIMENSION;
			body_alloc.width -= TAIL_HEIGHT;
			break;
		case GTK_POS_TOP: {
			int diff = TAIL_HEIGHT - SHADOW_DIMENSION;
			body_alloc.height -= SHADOW_DIMENSION * 2;
			body_alloc.y += diff;
		} break;
		case GTK_POS_BOTTOM:
		default:
			body_alloc.height -= TAIL_HEIGHT;
			break;
	}

	fl = gtk_widget_get_state_flags(widget);

	/* Warning: Using deprecated API */
	G_GNUC_BEGIN_IGNORE_DEPRECATIONS
	gtk_style_context_get_border_color(style, fl, &border_color);
	G_GNUC_END_IGNORE_DEPRECATIONS
	gtk_style_context_get_border(style, fl, &border);
	gtk_render_background(style, cr, body_alloc.x, body_alloc.y, body_alloc.width, body_alloc.height);

	gtk_render_frame(
		style, cr,
		body_alloc.x, body_alloc.y,
		body_alloc.width, body_alloc.height);
	gtk_style_context_set_state(style, fl);

	cairo_save(cr);
	cairo_set_line_width(cr, 1.3);
	cairo_set_source_rgba(cr, border_color.red, border_color.green, border_color.blue, border_color.alpha);
	budgie_popover_draw_tail(self, cr);
	cairo_clip(cr);
	cairo_move_to(cr, 0, 0);
	gtk_render_background(style, cr, alloc.x, alloc.y, alloc.width, alloc.height);
	cairo_restore(cr);

	child = gtk_bin_get_child(GTK_BIN(widget));
	if (child) {
		gtk_container_propagate_draw(GTK_CONTAINER(widget), child, cr);
	}

	return GDK_EVENT_PROPAGATE;
}

static void budgie_popover_add(GtkContainer* container, GtkWidget* widget) {
	BudgiePopover* self = NULL;

	self = BUDGIE_POPOVER(container);

	/* Only add internal area to self for real. Anything else goes to add_area */
	if (widget == self->priv->add_area) {
		GTK_CONTAINER_CLASS(budgie_popover_parent_class)->add(container, widget);
		return;
	}

	gtk_container_add(GTK_CONTAINER(self->priv->add_area), widget);
}

static gboolean budgie_popover_hide_self(gpointer v) {
	gtk_widget_hide(GTK_WIDGET(v));
	return G_SOURCE_REMOVE;
}

/**
 * budgie_popover_button_press:
 *
 * If the mouse button is pressed outside of our window, that's our cue to close.
 */
static gboolean budgie_popover_button_press(GtkWidget* widget, GdkEventButton* button, __budgie_unused__ gpointer udata) {
	gint x, y = 0;
	gint w, h = 0;
	gtk_window_get_position(GTK_WINDOW(widget), &x, &y);
	gtk_window_get_size(GTK_WINDOW(widget), &w, &h);

	gint root_x = (gint) button->x_root;
	gint root_y = (gint) button->y_root;

	/* Inside our window? Continue as normal. */
	gint scale_factor = gtk_widget_get_scale_factor(widget);

	if (((root_x * scale_factor) >= x && (root_x * scale_factor) <= x + (w * scale_factor)) &&
		((root_y * scale_factor) >= y && (root_y * scale_factor) <= y + (h * scale_factor))) {
		return GDK_EVENT_PROPAGATE;
	}

	/* Happened outside, we're done. */
	g_idle_add(budgie_popover_hide_self, widget);
	return GDK_EVENT_PROPAGATE;
}

/**
 * budgie_popover_key_press:
 *
 * If the Escape/Super key is pressed, then we also need to close.
 */
static gboolean budgie_popover_key_press(GtkWidget* widget, GdkEventKey* key, __budgie_unused__ gpointer udata) {
	switch (key->keyval) {
		case GDK_KEY_Escape:
		case GDK_KEY_Super_L:
		case GDK_KEY_Super_R:
			gtk_widget_hide(widget);
			return GDK_EVENT_STOP;
		default:
			return GDK_EVENT_PROPAGATE;
	}
}

/**
 * budgie_popover_disconnect:
 *
 * Our associated widget has died, so we must unref ourselves now.
 */
static void budgie_popover_disconnect(__budgie_unused__ GtkWidget* relative_to, BudgiePopover* self) {
	self->priv->relative_to = NULL;
	gtk_widget_destroy(GTK_WIDGET(self));
}

static void budgie_popover_set_property(GObject* object, guint id, const GValue* value, GParamSpec* spec) {
	BudgiePopover* self = BUDGIE_POPOVER(object);

	switch (id) {
		case PROP_RELATIVE_TO:
			if (self->priv->relative_to) {
				g_signal_handlers_disconnect_by_data(self->priv->relative_to, self);
			}
			self->priv->relative_to = g_value_get_object(value);
			if (self->priv->relative_to) {
				g_signal_connect(self->priv->relative_to, "destroy", G_CALLBACK(budgie_popover_disconnect), self);
				budgie_popover_compute_tail(self);
			}
			break;
		case PROP_POLICY:
			self->priv->policy = g_value_get_enum(value);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

static void budgie_popover_get_property(GObject* object, guint id, GValue* value, GParamSpec* spec) {
	BudgiePopover* self = BUDGIE_POPOVER(object);

	switch (id) {
		case PROP_RELATIVE_TO:
			g_value_set_object(value, self->priv->relative_to);
			break;
		case PROP_POLICY:
			g_value_set_enum(value, self->priv->policy);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID(object, id, spec);
			break;
	}
}

/**
 * budgie_popover_new:
 * @relative_to: The widget to show the popover for

 * Construct a new BudgiePopover object
 *
 * Returns: (transfer full): A newly created #BudgiePopover
 */
GtkWidget* budgie_popover_new(GtkWidget* relative_to) {
	return g_object_new(BUDGIE_TYPE_POPOVER, "relative-to", relative_to, "type", GTK_WINDOW_POPUP, NULL);
}

/**
 * budgie_popover_set_position_policy:
 * @policy:(type BudgiePopoverPositionPolicy): New policy to set
 *
 * Set the positioning policy employed by the popover
 */
void budgie_popover_set_position_policy(BudgiePopover* self, BudgiePopoverPositionPolicy policy) {
	g_return_if_fail(self != NULL);
	g_object_set(self, "position-policy", policy, NULL);
}

/**
 * budgie_popover_get_position_policy:
 *
 * Retrieve the currently active positioning policy for this popover
 *
 * Returns: The #BudgiePopoverPositionPolicy currently in use
 */
BudgiePopoverPositionPolicy budgie_popover_get_position_policy(BudgiePopover* self) {
	g_return_val_if_fail(self != NULL, 0);
	return self->priv->policy;
}
