/*
 * budgie-panel.h
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
#ifndef panel_toplevel_h
#define panel_toplevel_h

#include <glib-object.h>
#include <gtk/gtk.h>

#define PANEL_CSS "\
PanelToplevel {\
    border-width: 1px;\
    background-color: alpha(white, 0.0);\
    background-image: linear-gradient(to bottom,\
		alpha(shade (white, 0.2), 0.92),\
		alpha(shade (black, 1.0), 0.92));\
}\
.panel-shadow-top {\
    background-color: @transparent;\
    background-image: -gtk-gradient (linear,\
                     left top, left bottom,\
                     from (alpha (#000, 0.3)),\
                     to (alpha (#000, 0.0)));\
}\
.panel-shadow-bottom {\
    background-color: @transparent;\
    background-image: -gtk-gradient (linear,\
                     left bottom, left top,\
                     from (alpha (#000, 0.3)),\
                     to (alpha (#000, 0.0)));\
}\
MenuWindow {\
    border-radius: 3px;\
    border-width: 1px;\
}\
GtkListBoxRow {\
    background-image: none;\
    background-color: alpha(black, 0.0);\
}\
MenuWindow .trough {\
    background-color: alpha(black, 0.0);\
}\
"

typedef struct _PanelToplevel PanelToplevel;
typedef struct _PanelToplevelClass   PanelToplevelClass;

#define PANEL_TOPLEVEL_TYPE (panel_toplevel_get_type())
#define PANEL_TOPLEVEL(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), PANEL_TOPLEVEL_TYPE, PanelToplevel))
#define IS_PANEL_TOPLEVEL(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), PANEL_TOPLEVEL_TYPE))
#define PANEL_TOPLEVEL_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), PANEL_TOPLEVEL_TYPE, PanelToplevelClass))
#define IS_PANEL_TOPLEVEL_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), PANEL_TOPLEVEL_TYPE))
#define PANEL_TOPLEVEL_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), PANEL_TOPLEVEL_TYPE, PanelToplevelClass))

/* PanelToplevel object */
struct _PanelToplevel {
        GtkWindow parent;
        GtkWidget *shadow;

        GtkWidget *tasklist;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *menu;

        gboolean x11;
};

/* PanelToplevel class definition */
struct _PanelToplevelClass {
        GtkWindowClass parent_class;
};

GType panel_toplevel_get_type(void);

/* PanelToplevel methods */

/**
 * Construct a new PanelToplevel
 * @return A new PanelToplevel
 */
PanelToplevel* panel_toplevel_new(void);

#endif /* panel_toplevel_h */
