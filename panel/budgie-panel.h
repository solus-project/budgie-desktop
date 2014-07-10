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
#include <gdk/gdkx.h>

#define BUDGIE_SCHEMA "com.evolve-os.budgie.panel"
#define BUDGIE_PANEL_LOCATION "location"
#define PANEL_TOP_KEY "top"
#define PANEL_BOTTOM_KEY "bottom"

#define BUDGIE_STYLE_PANEL "budgie-panel"
#define BUDGIE_STYLE_MAX_PANEL "max-budgie-panel"
#define BUDGIE_STYLE_PANEL_TOP "top"
#define BUDGIE_STYLE_PANEL_ICON "launcher"
#define BUDGIE_STYLE_MENU_ICON "menu-icon"
#define BUDGIE_STYLE_MESSAGE_AREA "message-area"
#define BUDGIE_STYLE_MAX_MESSAGE_AREA "max-message-area"

typedef struct _BudgiePanel BudgiePanel;
typedef struct _BudgiePanelClass   BudgiePanelClass;

#define BUDGIE_PANEL_TYPE (budgie_panel_get_type())
#define BUDGIE_PANEL(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_PANEL_TYPE, BudgiePanel))
#define IS_BUDGIE_PANEL(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_PANEL_TYPE))
#define BUDGIE_PANEL_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_PANEL_TYPE, BudgiePanelClass))
#define IS_BUDGIE_PANEL_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_PANEL_TYPE))
#define BUDGIE_PANEL_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_PANEL_TYPE, BudgiePanelClass))

typedef enum {
        PANEL_TOP,
        PANEL_BOTTOM
} BudgiePanelPosition;

/* BudgiePanel object */
struct _BudgiePanel {
        GtkWindow parent;

        GtkWidget *widgets;
        GtkWidget *tasklist;
        GtkWidget *power;
        GtkWidget *clock;
        GtkWidget *sound;
        GtkWidget *menu;

        gboolean x11;
        BudgiePanelPosition position;
        GSettings *settings;
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
BudgiePanel *budgie_panel_new(void);

/**
 * Notify BudgiePanel that the window area is obscured
 * @param panel BudgiePanel instance
 * @param obscured Boolean indicated that the workspace is obscured by
 * a maximized screen
 */
void budgie_panel_set_view_obscured(BudgiePanel *panel,
                                    gboolean obscured);

/**
 * Request that the main menu is shown to the user
 * @param panel BudgiePanel instance
 */
void budgie_panel_show_menu(BudgiePanel *panel);

#endif /* budgie_panel_h */
