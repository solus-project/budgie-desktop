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

#ifndef NA_ITEM_H
#define NA_ITEM_H

#include <gtk/gtk.h>

G_BEGIN_DECLS

#define NA_TYPE_ITEM            (na_item_get_type ())
#define NA_ITEM(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), NA_TYPE_ITEM, NaItem))
#define NA_IS_ITEM(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), NA_TYPE_ITEM))
#define NA_ITEM_GET_IFACE(obj)  (G_TYPE_INSTANCE_GET_INTERFACE ((obj), NA_TYPE_ITEM, NaItemInterface))

typedef struct _NaItem          NaItem;
typedef struct _NaItemInterface NaItemInterface;

typedef enum
{
  NA_ITEM_CATEGORY_APPLICATION_STATUS,
  NA_ITEM_CATEGORY_COMMUNICATIONS,
  NA_ITEM_CATEGORY_SYSTEM_SERVICES,
  NA_ITEM_CATEGORY_HARDWARE,
} NaItemCategory;

struct _NaItemInterface
{
  GTypeInterface g_iface;

  const gchar *   (* get_id)              (NaItem *item);
  NaItemCategory  (* get_category)        (NaItem *item);

  gboolean        (* draw_on_parent)      (NaItem    *item,
                                           GtkWidget *parent,
                                           cairo_t   *parent_cr);
};

GType           na_item_get_type        (void);
const gchar    *na_item_get_id          (NaItem *item);
NaItemCategory  na_item_get_category    (NaItem *item);
gboolean        na_item_draw_on_parent  (NaItem    *item,
                                         GtkWidget *parent,
                                         cairo_t   *parent_cr);

G_END_DECLS

#endif
