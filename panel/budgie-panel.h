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
#ifndef budgie_panel_h
#define budgie_panel_h

#include <glib-object.h>
#include <gtk/gtk.h>

#define PANEL_CSS "\
BudgiePanel {\
    border-width: 1px;\
    background-color: alpha(white, 0.0);\
    background-image: linear-gradient(to bottom,\
		alpha(shade (white, 0.2), 0.92),\
		alpha(shade (black, 1.0), 0.92));\
}\
.panel-shadow.top {\
    background-color: @transparent;\
    background-image: -gtk-gradient (linear,\
                     left top, left bottom,\
                     from (alpha (#000, 0.3)),\
                     to (alpha (#000, 0.0)));\
}\
.panel-shadow {\
    background-color: @transparent;\
    background-image: -gtk-gradient (linear,\
                     left bottom, left top,\
                     from (alpha (#000, 0.3)),\
                     to (alpha (#000, 0.0)));\
}\
.panel-applet {\
    background-image: none;\
    border-color: alpha(white, 0.12);\
    border-radius: 6px;\
    border: solid alpha(white, 0.1) 1px;\
}\
BudgiePanel GtkButton:active {\
    color: white;\
    text-shadow: 0px 1px black;\
    transition: all 200ms ease-in;\
    background-image: none;\
    border: 1px solid alpha(white, 0.0);\
    background-color: alpha(black, 0.72);\
}\
BudgiePanel GtkButton {\
    color: alpha(white, 0.7);\
    text-shadow: 0px 1px alpha(black, 0.8);\
    transition: all 200ms ease-out; \
}"

typedef struct _BudgiePanel BudgiePanel;
typedef struct _BudgiePanelClass   BudgiePanelClass;

#define BUDGIE_PANEL_TYPE (budgie_panel_get_type())
#define BUDGIE_PANEL(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_PANEL_TYPE, BudgiePanel))
#define IS_BUDGIE_PANEL(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_PANEL_TYPE))
#define BUDGIE_PANEL_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_PANEL_TYPE, BudgiePanelClass))
#define IS_BUDGIE_PANEL_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_PANEL_TYPE))
#define BUDGIE_PANEL_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_PANEL_TYPE, BudgiePanelClass))

/* BudgiePanel object */
struct _BudgiePanel {
        GtkWindow parent;
        GtkWidget *shadow;

        GtkWidget *tasklist;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *menu_window;
};

/* BudgiePanel class definition */
struct _BudgiePanelClass {
        GtkWindowClass parent_class;
};

GType budgie_panel_get_type(void);

/* BudgiePanel methods */

/**
 * Construct a new BudgiePanel
 * @return A new BudgiePanel
 */
BudgiePanel* budgie_panel_new(void);

#endif /* budgie_panel_h */
