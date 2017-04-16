/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* na-tray-tray.h
 * Copyright (C) 2002 Anders Carlsson <andersca@gnu.org>
 * Copyright (C) 2003-2006 Vincent Untz
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 *
 * Used to be: eggtraytray.h
 */

#ifndef __NA_TRAY_H__
#define __NA_TRAY_H__

#include <gdk/gdkx.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define NA_TYPE_TRAY na_tray_get_type ()
G_DECLARE_FINAL_TYPE (NaTray, na_tray, NA, TRAY, GtkBin)

NaTray         *na_tray_new_for_screen  (GtkOrientation orientation);
void            na_tray_set_orientation	(NaTray        *tray,
					 GtkOrientation orientation);
GtkOrientation  na_tray_get_orientation (NaTray        *tray);
void            na_tray_set_padding     (NaTray        *tray,
					 gint           padding);
void            na_tray_set_icon_size   (NaTray        *tray,
					 gint           icon_size);
void            na_tray_set_colors      (NaTray        *tray,
					 GdkRGBA       *fg,
					 GdkRGBA       *error,
					 GdkRGBA       *warning,
					 GdkRGBA       *success);

G_END_DECLS

#endif /* __NA_TRAY_H__ */
