/*
 * Copyright (C) 2002 Red Hat, Inc.
 * Copyright (C) 2003-2006 Vincent Untz
 * Copyright (C) 2007 Christian Persch
 * Copyright (C) 2017 Colomban Wendling <cwendling@hypra.fr>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 */

/* Well, actuall'y is the Tray itself, the container for the items.  But
 * NaTray is already taken for the XEMBED part, so for now it's called NaGrid,
 * don't make a big deal out of it. */

#include "config.h"
#include <gtk/gtk.h>

#include "na-grid.h"

#include "na-tray.h"

#define MIN_ICON_SIZE_DEFAULT 24

typedef struct
{
  GtkOrientation  orientation;
  gint            index;
  NaGrid         *grid;
} SortData;

struct _NaGrid
{
  GtkGrid    parent;

  gint       icon_padding;
  gint       icon_size;

  gint       min_icon_size;
  gint       cols;
  gint       rows;
  gint       length;

  GSList    *hosts;
  GSList    *items;
};

enum
{
  PROP_0,
  PROP_ICON_PADDING,
  PROP_ICON_SIZE
};

G_DEFINE_TYPE (NaGrid, na_grid, GTK_TYPE_GRID)

static gint
compare_items (gconstpointer a,
               gconstpointer b)
{
  NaItem *item1;
  NaItem *item2;
  NaItemCategory c1;
  NaItemCategory c2;
  const gchar *id1;
  const gchar *id2;

  item1 = (NaItem *) a;
  item2 = (NaItem *) b;

  c1 = na_item_get_category (item1);
  c2 = na_item_get_category (item2);

  if (c1 < c2)
    return -1;
  else if (c1 > c2)
    return 1;

  id1 = na_item_get_id (item1);
  id2 = na_item_get_id (item2);

  return g_strcmp0 (id1, id2);
}

static void
sort_items (GtkWidget *item,
            SortData  *data)
{
  gint col, row, left_attach, top_attach;

  /* row / col number depends on whether we are horizontal or vertical */
  if (data->orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      col = data->index / data->grid->rows;
      row = data->index % data->grid->rows;
    }
  else
    {
      row = data->index / data->grid->cols;
      col = data->index % data->grid->cols;
    }

  /* only update item position if it has changed from current */
  gtk_container_child_get (GTK_CONTAINER (data->grid),
                           item,
                           "left-attach", &left_attach,
                           "top-attach", &top_attach,
                           NULL);

  if (left_attach != col || top_attach != row)
    {
      gtk_container_child_set (GTK_CONTAINER (data->grid),
                               item,
                               "left-attach", col,
                               "top-attach", row,
                               NULL);
    }

  /* increment to index of next item */
  data->index++;
}

static void
refresh_grid (NaGrid *self)
{
  GtkOrientation orientation;
  GtkAllocation allocation;
  gint rows, cols, length;

  orientation = gtk_orientable_get_orientation (GTK_ORIENTABLE (self));
  gtk_widget_get_allocation (GTK_WIDGET (self), &allocation);
  length = g_slist_length (self->items);

  if (orientation == GTK_ORIENTATION_HORIZONTAL)
    {
      gtk_grid_set_row_homogeneous (GTK_GRID (self), TRUE);
      gtk_grid_set_column_homogeneous (GTK_GRID (self), TRUE);
      rows = MAX (1, allocation.height / self->min_icon_size);
      cols = MAX (1, length / rows);
      if (length % rows)
        cols++;
    }
  else
    {
      gtk_grid_set_row_homogeneous (GTK_GRID (self), TRUE);
      gtk_grid_set_column_homogeneous (GTK_GRID (self), TRUE);
      cols = MAX (1, allocation.width / self->min_icon_size);
      rows = MAX (1, length / cols);
      if (length % cols)
        rows++;
    }

  if (self->cols != cols || self->rows != rows || self->length != length)
    {
      self->cols = cols;
      self->rows = rows;
      self->length = length;

      SortData data;
      data.orientation = gtk_orientable_get_orientation (GTK_ORIENTABLE (self));
      data.index = 0;
      data.grid = self;

      g_slist_foreach (self->items,
                       (GFunc) sort_items,
                       &data);
    }
}

void
na_grid_set_min_icon_size (NaGrid *grid,
                           gint    min_icon_size)
{
  g_return_if_fail (NA_IS_GRID (grid));

  grid->min_icon_size = min_icon_size;
  grid->icon_size = min_icon_size;

  refresh_grid (grid);
}

static void
item_added_cb (NaHost *host,
               NaItem *item,
               NaGrid *self)
{
  g_return_if_fail (NA_IS_HOST (host));
  g_return_if_fail (NA_IS_ITEM (item));
  g_return_if_fail (NA_IS_GRID (self));

  g_object_bind_property (self, "orientation",
                          item, "orientation",
                          G_BINDING_SYNC_CREATE);

  self->items = g_slist_prepend (self->items, item);

  gtk_widget_set_hexpand (GTK_WIDGET (item), TRUE);
  gtk_widget_set_vexpand (GTK_WIDGET (item), TRUE);
  gtk_grid_attach (GTK_GRID (self),
                   GTK_WIDGET (item),
                   self->cols - 1,
                   self->rows - 1,
                   1, 1);

  self->items = g_slist_sort (self->items, compare_items);
  refresh_grid (self);
}

static void
item_removed_cb (NaHost *host,
                 NaItem *item,
                 NaGrid *self)
{
  g_return_if_fail (NA_IS_HOST (host));
  g_return_if_fail (NA_IS_ITEM (item));
  g_return_if_fail (NA_IS_GRID (self));

  gtk_container_remove (GTK_CONTAINER (self), GTK_WIDGET (item));
  self->items = g_slist_remove (self->items, item);
  refresh_grid (self);
}

static void
na_grid_init (NaGrid *self)
{
  self->icon_padding = 2;

  self->min_icon_size = MIN_ICON_SIZE_DEFAULT;
  self->cols = 1;
  self->rows = 1;
  self->length = 0;

  self->hosts = NULL;
  self->items = NULL;

  gtk_grid_set_row_homogeneous (GTK_GRID (self), TRUE);
  gtk_grid_set_column_homogeneous (GTK_GRID (self), TRUE);

}

static void
add_host (NaGrid *self,
          NaHost *host)
{
  self->hosts = g_slist_prepend (self->hosts, host);

  g_object_bind_property (self, "icon-padding", host, "icon-padding",
                          G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE);
  g_object_bind_property (self, "icon-size", host, "icon-size",
                          G_BINDING_DEFAULT | G_BINDING_SYNC_CREATE);

  g_signal_connect_object (host, "item-added",
                           G_CALLBACK (item_added_cb), self, 0);
  g_signal_connect_object (host, "item-removed",
                           G_CALLBACK (item_removed_cb), self, 0);
}

static void
na_grid_style_updated (GtkWidget *widget)
{
  NaGrid          *self = NA_GRID (widget);
  GtkStyleContext *context;
  GSList          *node;

  if (GTK_WIDGET_CLASS (na_grid_parent_class)->style_updated)
    GTK_WIDGET_CLASS (na_grid_parent_class)->style_updated (widget);

  context = gtk_widget_get_style_context (widget);

  for (node = self->hosts; node; node = node->next)
    {
      gtk_style_context_save (context);
      na_host_style_updated (node->data, context);
      gtk_style_context_restore (context);
    }
}

/* Custom drawing because system-tray items need weird stuff. */
static gboolean
na_grid_draw (GtkWidget *grid,
              cairo_t   *cr)
{
  GList *child;
  GList *children = gtk_container_get_children (GTK_CONTAINER (grid));

  for (child = children; child; child = child->next)
    {
      if (! NA_IS_ITEM (child->data) ||
          ! na_item_draw_on_parent (child->data, grid, cr))
	{
	  if (gtk_widget_is_drawable (child->data) &&
	      gtk_cairo_should_draw_window (cr, gtk_widget_get_window (child->data)))
	    gtk_container_propagate_draw (GTK_CONTAINER (grid), child->data, cr);
	}
    }

  g_list_free (children);

  return TRUE;
}

static void
na_grid_realize (GtkWidget *widget)
{
  NaGrid *self = NA_GRID (widget);
  GdkScreen *screen;
  GtkOrientation orientation;
  NaHost *tray_host;

  GTK_WIDGET_CLASS (na_grid_parent_class)->realize (widget);

  /* Instantiate the hosts now we have a screen */
  screen = gtk_widget_get_screen (GTK_WIDGET (self));
  orientation = gtk_orientable_get_orientation (GTK_ORIENTABLE (self));
  tray_host = na_tray_new_for_screen (screen, orientation);
  g_object_bind_property (self, "orientation",
                          tray_host, "orientation",
                          G_BINDING_DEFAULT);

  add_host (self, tray_host);
}

static void
na_grid_unrealize (GtkWidget *widget)
{
  NaGrid *self = NA_GRID (widget);

  if (self->hosts != NULL)
    {
      g_slist_free_full (self->hosts, g_object_unref);
      self->hosts = NULL;
    }

  g_clear_pointer (&self->items, g_slist_free);

  GTK_WIDGET_CLASS (na_grid_parent_class)->unrealize (widget);
}

static void
na_grid_size_allocate (GtkWidget     *widget,
                       GtkAllocation *allocation)
{
  GTK_WIDGET_CLASS (na_grid_parent_class)->size_allocate (widget, allocation);
  refresh_grid (NA_GRID (widget));
}

static void
na_grid_get_property (GObject    *object,
                      guint       property_id,
                      GValue     *value,
                      GParamSpec *pspec)
{
  NaGrid *self = NA_GRID (object);

  switch (property_id)
    {
      case PROP_ICON_PADDING:
        g_value_set_int (value, self->icon_padding);
        break;

      case PROP_ICON_SIZE:
        g_value_set_int (value, self->icon_size);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
na_grid_set_property (GObject      *object,
                      guint         property_id,
                      const GValue *value,
                      GParamSpec   *pspec)
{
  NaGrid *self = NA_GRID (object);

  switch (property_id)
    {
      case PROP_ICON_PADDING:
        self->icon_padding = g_value_get_int (value);
        break;

      case PROP_ICON_SIZE:
        self->icon_size = g_value_get_int (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
na_grid_class_init (NaGridClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  gobject_class->get_property = na_grid_get_property;
  gobject_class->set_property = na_grid_set_property;

  widget_class->draw = na_grid_draw;
  widget_class->realize = na_grid_realize;
  widget_class->unrealize = na_grid_unrealize;
  widget_class->style_updated = na_grid_style_updated;
  widget_class->size_allocate = na_grid_size_allocate;

  g_object_class_install_property (gobject_class, PROP_ICON_PADDING,
    g_param_spec_int ("icon-padding",
                      "Padding around icons",
                      "Padding that should be put around icons, in pixels",
                      0, G_MAXINT, 0,
                      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  g_object_class_install_property (gobject_class, PROP_ICON_SIZE,
    g_param_spec_int ("icon-size",
                      "Icon size",
                      "If non-zero, hardcodes the size of the icons in pixels",
                      0, G_MAXINT, 0,
                      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));
}

GtkWidget *
na_grid_new (GtkOrientation  orientation)
{
  return g_object_new (NA_TYPE_GRID,
                       "orientation", orientation,
                       NULL);
}

void
na_grid_force_redraw (NaGrid *grid)
{
  GSList *node;

  for (node = grid->hosts; node; node = node->next)
    na_host_force_redraw (node->data);
}
