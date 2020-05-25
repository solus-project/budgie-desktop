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

#include "na-item.h"

G_DEFINE_INTERFACE_WITH_CODE (NaItem, na_item, GTK_TYPE_WIDGET,
                              g_type_interface_add_prerequisite (g_define_type_id,
                                                                 GTK_TYPE_ORIENTABLE);)

static gboolean
na_item_draw_on_parent_default (NaItem     *item,
                                GtkWidget  *parent,
                                cairo_t    *parent_cr)
{
  return FALSE;
}

static void
na_item_default_init (NaItemInterface *iface)
{
  iface->draw_on_parent = na_item_draw_on_parent_default;
}

const gchar *
na_item_get_id (NaItem *item)
{
  NaItemInterface *iface;

  g_return_val_if_fail (NA_IS_ITEM (item), NULL);

  iface = NA_ITEM_GET_IFACE (item);
  g_return_val_if_fail (iface->get_id != NULL, NULL);

  return iface->get_id (item);
}

NaItemCategory
na_item_get_category (NaItem *item)
{
  NaItemInterface *iface;

  g_return_val_if_fail (NA_IS_ITEM (item),
                        NA_ITEM_CATEGORY_APPLICATION_STATUS);

  iface = NA_ITEM_GET_IFACE (item);
  g_return_val_if_fail (iface->get_category != NULL,
                        NA_ITEM_CATEGORY_APPLICATION_STATUS);

  return iface->get_category (item);
}

/*
 * Fairly ugly hack because system-tray/NaTrayChild uses a weird hack for
 * drawing itself.  I'm not sure it's still needed with the current GTK3
 * drawing where not all widgets have an own window, but well.
 *
 * Should return %TRUE if it handled itself, or %FALSE if the parent should
 * draw normally.  Default is to draw normally.
 */
gboolean
na_item_draw_on_parent (NaItem    *item,
                        GtkWidget *parent,
                        cairo_t   *parent_cr)
{
  NaItemInterface *iface;

  g_return_val_if_fail (NA_IS_ITEM (item), FALSE);
  g_return_val_if_fail (GTK_IS_WIDGET (parent), FALSE);

  iface = NA_ITEM_GET_IFACE (item);
  g_return_val_if_fail (iface->draw_on_parent != NULL, FALSE);

  return iface->draw_on_parent (item, parent, parent_cr);
}
