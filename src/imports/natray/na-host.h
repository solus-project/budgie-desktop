/*
 * Copyright (C) 2016 Alberts Muktupāvels
 * Copyright (C) 2017 Colomban Wendling <cwendling@hypra.fr>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef NA_HOST_H
#define NA_HOST_H

#include "na-item.h"

G_BEGIN_DECLS

#define NA_TYPE_HOST            (na_host_get_type ())
#define NA_HOST(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), NA_TYPE_HOST, NaHost))
#define NA_IS_HOST(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), NA_TYPE_HOST))
#define NA_HOST_GET_IFACE(obj)  (G_TYPE_INSTANCE_GET_INTERFACE ((obj), NA_TYPE_HOST, NaHostInterface))

typedef struct _NaHost          NaHost;
typedef struct _NaHostInterface NaHostInterface;

struct _NaHostInterface
{
  GTypeInterface parent;

  void (*force_redraw)         (NaHost          *host);
  void (*style_updated)        (NaHost          *host,
                                GtkStyleContext *context);
};

GType   na_host_get_type          (void);
void    na_host_force_redraw      (NaHost          *host);
void    na_host_style_updated     (NaHost          *host,
                                   GtkStyleContext *context);
void    na_host_emit_item_added   (NaHost          *host,
                                   NaItem          *item);
void    na_host_emit_item_removed (NaHost          *host,
                                   NaItem          *item);

G_END_DECLS

#endif
