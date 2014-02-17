/*
 * budgie-popover.h
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
#ifndef budgie_popover_h
#define budgie_popover_h

#include <glib-object.h>
#include <gtk/gtk.h>

typedef struct _BudgiePopover BudgiePopover;
typedef struct _BudgiePopoverClass   BudgiePopoverClass;

#define BUDGIE_POPOVER_TYPE (budgie_popover_get_type())
#define BUDGIE_POPOVER(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_POPOVER_TYPE, BudgiePopover))
#define IS_BUDGIE_POPOVER(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_POPOVER_TYPE))
#define BUDGIE_POPOVER_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_POPOVER_TYPE, BudgiePopoverClass))
#define IS_BUDGIE_POPOVER_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_POPOVER_TYPE))
#define BUDGIE_POPOVER_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_POPOVER_TYPE, BudgiePopoverClass))

/* BudgiePopover object */
struct _BudgiePopover {
        GtkWindow parent;
        gint widg_x;
        gint widg_y;
        gboolean top;
};

/* BudgiePopover class definition */
struct _BudgiePopoverClass {
        GtkWindowClass parent_class;
};

GType budgie_popover_get_type(void);

/* BudgiePopover methods */

/**
 * Construct a new BudgiePopover
 * @return A new BudgiePopover
 */
GtkWidget *budgie_popover_new(void);

/**
 * Present a BudgiePopover on screen
 * @param self BudgiePopover instance
 * @param parent Parent to show the popover relative to
 */
void budgie_popover_present(BudgiePopover *self,
                            GtkWidget *parent);

#endif /* budgie_popover_h */
