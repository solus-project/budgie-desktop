#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <gtk/gtk.h>

/*
 * GNOME panel x stuff
 *
 * Copyright (C) 2000, 2001 Eazel, Inc.
 *               2002 Sun Microsystems Inc.
 *
 * Authors: George Lebl <jirka@5z.com>
 *          Mark McLoughlin <mark@skynet.ie>
 *
 *  Contains code from the Window Maker window manager
 *
 *  Copyright (c) 1997-2002 Alfredo K. Kojima

 */
void
xstuff_set_wmspec_strut (GdkWindow *window,
			 int        left,
			 int        right,
			 int        top,
			 int        bottom);

void
xstuff_delete_property (GdkWindow *window, const char *name);

