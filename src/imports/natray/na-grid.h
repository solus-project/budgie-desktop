/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* na-tray-tray.h
 * Copyright (C) 2002 Anders Carlsson <andersca@gnu.org>
 * Copyright (C) 2003-2006 Vincent Untz
 * Copyright (C) 2017 Colomban Wendling <cwendling@hypra.fr>
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
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Used to be: eggtraytray.h
 */

#ifndef NA_GRID_H
#define NA_GRID_H

#include <gdk/gdkx.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

#define NA_TYPE_GRID (na_grid_get_type ())
G_DECLARE_FINAL_TYPE (NaGrid, na_grid, NA, GRID, GtkGrid)

void            na_grid_set_min_icon_size       (NaGrid *grid,
                                                 gint    min_icon_size);
GtkWidget      *na_grid_new                     (GtkOrientation orientation);
void            na_grid_force_redraw            (NaGrid *grid);

G_END_DECLS

#endif /* __NA_GRID_H__ */
