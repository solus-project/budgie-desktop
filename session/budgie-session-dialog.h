/*
 * budgie-session-dialog.h
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
#ifndef budgie_session_dialog_h
#define budgie_session_dialog_h

#include <glib-object.h>
#include <gtk/gtk.h>

#include "sd_logind_proxy.h"
#include "dm_seat.h"

typedef struct _BudgieSessionDialog BudgieSessionDialog;
typedef struct _BudgieSessionDialogClass   BudgieSessionDialogClass;

#define BUDGIE_SESSION_DIALOG_TYPE (budgie_session_dialog_get_type())
#define BUDGIE_SESSION_DIALOG(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_SESSION_DIALOG_TYPE, BudgieSessionDialog))
#define IS_BUDGIE_SESSION_DIALOG(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_SESSION_DIALOG_TYPE))
#define BUDGIE_SESSION_DIALOG_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_SESSION_DIALOG_TYPE, BudgieSessionDialogClass))
#define IS_BUDGIE_SESSION_DIALOG_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_SESSION_DIALOG_TYPE))
#define BUDGIE_SESSION_DIALOG_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_SESSION_DIALOG_TYPE, BudgieSessionDialogClass))

/* BudgieSessionDialog object */
struct _BudgieSessionDialog {
        GtkWindow parent;
        SdLoginManager *proxy;
        DmSeat *seat_proxy;
};

/* BudgieSessionDialog class definition */
struct _BudgieSessionDialogClass {
        GtkWindowClass parent_class;
};

GType budgie_session_dialog_get_type(void);

/* BudgieSessionDialog methods */

/**
 * Construct a new BudgieSessionDialog
 * @return A new BudgieSessionDialog
 */
BudgieSessionDialog *budgie_session_dialog_new(void);

#endif /* budgie_session_dialog_h */
