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

/* Initialisation */
static void budgie_popover_class_init(BudgiePopoverClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_popover_dispose;
}


static void budgie_popover_init(BudgiePopover *self)
{
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
