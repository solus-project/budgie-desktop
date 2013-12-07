/*
 * budgie-panel.c
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

#include "budgie-panel.h"

G_DEFINE_TYPE(BudgiePanel, budgie_panel, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void budgie_panel_class_init(BudgiePanelClass *klass);
static void budgie_panel_init(BudgiePanel *self);
static void budgie_panel_dispose(GObject *object);

/* Initialisation */
static void budgie_panel_class_init(BudgiePanelClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_panel_dispose;
}

static void budgie_panel_init(BudgiePanel *self)
{
        /* Ensure we close when destroyed */
        g_signal_connect(self, "destroy", G_CALLBACK(gtk_main_quit), NULL);

        /* And now show ourselves */
        gtk_widget_show_all(GTK_WIDGET(self));
}

static void budgie_panel_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (budgie_panel_parent_class)->dispose (object);
}

/* Utility; return a new BudgiePanel */
BudgiePanel* budgie_panel_new(void)
{
        BudgiePanel *self;

        self = g_object_new(BUDGIE_PANEL_TYPE, NULL);
        return self;
}
