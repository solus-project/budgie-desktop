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

#include "na-host.h"
#include "na-item.h"

enum
{
  SIGNAL_ITEM_ADDED,
  SIGNAL_ITEM_REMOVED,

  LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0 };

G_DEFINE_INTERFACE (NaHost, na_host, G_TYPE_OBJECT)

static void
na_host_default_init (NaHostInterface *iface)
{
  signals[SIGNAL_ITEM_ADDED] =
    g_signal_new ("item-added", G_TYPE_FROM_INTERFACE (iface),
                  G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL,
                  G_TYPE_NONE, 1, NA_TYPE_ITEM);

  signals[SIGNAL_ITEM_REMOVED] =
    g_signal_new ("item-removed", G_TYPE_FROM_INTERFACE (iface),
                  G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL,
                  G_TYPE_NONE, 1, NA_TYPE_ITEM);

  g_object_interface_install_property (iface,
    g_param_spec_int ("icon-padding",
                      "Padding around icons",
                      "Padding that should be put around icons, in pixels",
                      0, G_MAXINT, 0,
                      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  g_object_interface_install_property (iface,
    g_param_spec_int ("icon-size",
                      "Icon size",
                      "If non-zero, hardcodes the size of the icons in pixels",
                      0, G_MAXINT, 0,
                      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  iface->style_updated = NULL;
}

void
na_host_force_redraw (NaHost *host)
{
  NaHostInterface *iface;

  g_return_if_fail (NA_IS_HOST (host));

  iface = NA_HOST_GET_IFACE (host);

  if (iface->force_redraw != NULL)
    iface->force_redraw (host);
}

void
na_host_style_updated (NaHost          *host,
                       GtkStyleContext *context)
{
  NaHostInterface *iface;

  g_return_if_fail (NA_IS_HOST (host));

  iface = NA_HOST_GET_IFACE (host);

  if (iface->style_updated != NULL)
    iface->style_updated (host, context);
}

void
na_host_emit_item_added (NaHost *host,
                         NaItem *item)
{
  g_signal_emit (host, signals[SIGNAL_ITEM_ADDED], 0, item);
}

void
na_host_emit_item_removed (NaHost *host,
                           NaItem *item)
{
  g_signal_emit (host, signals[SIGNAL_ITEM_REMOVED], 0, item);
}
