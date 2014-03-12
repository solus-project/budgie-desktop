/*
 * budgie-session-dialog.c
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

#include "budgie-session-dialog.h"

G_DEFINE_TYPE(BudgieSessionDialog, budgie_session_dialog, GTK_TYPE_WINDOW)

/* Boilerplate GObject code */
static void budgie_session_dialog_class_init(BudgieSessionDialogClass *klass);
static void budgie_session_dialog_init(BudgieSessionDialog *self);
static void budgie_session_dialog_dispose(GObject *object);

/* Initialisation */
static void budgie_session_dialog_class_init(BudgieSessionDialogClass *klass)
{
        GObjectClass *g_object_class;

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_session_dialog_dispose;
}


static void budgie_session_dialog_init(BudgieSessionDialog *self)
{
        gtk_window_set_position(GTK_WINDOW(self), GTK_WIN_POS_CENTER_ALWAYS);
        gtk_window_set_title(GTK_WINDOW(self), "End your session?");
        gtk_window_set_default_size(GTK_WINDOW(self), 400, 400);
}

static void budgie_session_dialog_dispose(GObject *object)
{
        /* Destruct */
        G_OBJECT_CLASS (budgie_session_dialog_parent_class)->dispose (object);
}

/* Utility; return a new BudgieSessionDialog */
BudgieSessionDialog* budgie_session_dialog_new(void)
{
        BudgieSessionDialog *self;

        self = g_object_new(BUDGIE_SESSION_DIALOG_TYPE, NULL);
        return self;
}
