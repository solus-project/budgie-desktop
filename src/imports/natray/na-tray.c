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

#include <config.h>
#include <string.h>

#include <gtk/gtk.h>

#include "na-tray-manager.h"

#include "na-tray.h"

typedef struct
{
  NaTrayManager *tray_manager;
  GSList        *all_trays;
  GHashTable    *icon_table;
  GHashTable    *tip_table;
} TraysScreen;

struct _NaTrayPrivate
{
  GdkScreen   *screen;
  TraysScreen *trays_screen;

  guint idle_redraw_id;

  GtkOrientation orientation;
  gint           icon_padding;
  gint           icon_size;
};

typedef struct
{
  char  *text;
  glong  id;
  glong  timeout;
} IconTipBuffer;

typedef struct
{
  NaTray *tray;      /* tray containing the tray icon */
  GtkWidget  *icon;      /* tray icon sending the message */
  GtkWidget  *fixedtip;
  guint       source_id;
  glong       id;        /* id of the current message */
  GSList     *buffer;    /* buffered messages */
} IconTip;

enum
{
  PROP_0,
  PROP_ORIENTATION,
  PROP_ICON_PADDING,
  PROP_ICON_SIZE,
  PROP_SCREEN
};

static gboolean     initialized   = FALSE;
static TraysScreen *trays_screens = NULL;

static void icon_tip_show_next (IconTip *icontip);

/* NaTray */
static void na_host_init          (NaHostInterface *iface);
static void na_tray_style_updated (NaHost          *host,
                                   GtkStyleContext *context);
static void na_tray_force_redraw  (NaHost          *host);

G_DEFINE_TYPE_WITH_CODE (NaTray, na_tray, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (GTK_TYPE_ORIENTABLE, NULL)
                         G_IMPLEMENT_INTERFACE (NA_TYPE_HOST, na_host_init))

static void
na_host_init (NaHostInterface *iface)
{
  iface->force_redraw = na_tray_force_redraw;
  iface->style_updated = na_tray_style_updated;
}

static NaTray *
get_tray (TraysScreen *trays_screen)
{
  if (trays_screen->all_trays == NULL)
    return NULL;

  return trays_screen->all_trays->data;
}

static void
tray_added (NaTrayManager *manager,
            NaTrayChild   *icon,
            TraysScreen   *trays_screen)
{
  NaTray *tray;
  NaTrayPrivate *priv;

  tray = get_tray (trays_screen);
  if (tray == NULL)
    return;

  priv = tray->priv;

  g_assert (priv->trays_screen == trays_screen);

  g_hash_table_insert (trays_screen->icon_table, icon, tray);

  na_host_emit_item_added (NA_HOST (tray), NA_ITEM (icon));

  /*Does not seem to be needed anymore and can cause a render issue with hidpi*/
  /*gtk_widget_show (GTK_WIDGET (icon));*/
}

static void
tray_removed (NaTrayManager *manager,
              NaTrayChild   *icon,
              TraysScreen   *trays_screen)
{
  NaTray *tray;

  tray = g_hash_table_lookup (trays_screen->icon_table, icon);
  if (tray == NULL)
    return;

  g_assert (tray->priv->trays_screen == trays_screen);

  na_host_emit_item_removed (NA_HOST (tray), NA_ITEM (icon));

  g_hash_table_remove (trays_screen->icon_table, icon);
  /* this will also destroy the tip associated to this icon */
  g_hash_table_remove (trays_screen->tip_table, icon);
}

static void
update_size_and_orientation (NaTray *tray)
{
  NaTrayPrivate *priv = tray->priv;

  /* This only happens when setting the property during object construction */
  if (!priv->trays_screen)
    return;

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_orientation (priv->trays_screen->tray_manager,
                                     priv->orientation);
}

static void
na_tray_init (NaTray *tray)
{
  NaTrayPrivate *priv;

  priv = tray->priv = G_TYPE_INSTANCE_GET_PRIVATE (tray, NA_TYPE_TRAY, NaTrayPrivate);

  priv->screen = NULL;
  priv->orientation = GTK_ORIENTATION_HORIZONTAL;
  priv->icon_padding = 0;
  priv->icon_size = 0;
}

static GObject *
na_tray_constructor (GType type,
                     guint n_construct_properties,
                     GObjectConstructParam *construct_params)
{
  GObject *object;
  NaTray *tray;
  NaTrayPrivate *priv;
  int screen_number;

  object = G_OBJECT_CLASS (na_tray_parent_class)->constructor (type,
                                                               n_construct_properties,
                                                               construct_params);
  tray = NA_TRAY (object);
  priv = tray->priv;

  g_assert (priv->screen != NULL);

  if (!initialized)
    {
      trays_screens = g_new0 (TraysScreen, 1);
      initialized = TRUE;
    }

  screen_number = gdk_x11_screen_get_screen_number (priv->screen);

  if (trays_screens [screen_number].tray_manager == NULL)
    {
      NaTrayManager *tray_manager;

      tray_manager = na_tray_manager_new ();

      if (na_tray_manager_manage_screen (tray_manager, priv->screen))
        {
          trays_screens [screen_number].tray_manager = tray_manager;

          g_signal_connect (tray_manager, "tray_icon_added",
                            G_CALLBACK (tray_added),
                            &trays_screens [screen_number]);
          g_signal_connect (tray_manager, "tray_icon_removed",
                            G_CALLBACK (tray_removed),
                            &trays_screens [screen_number]);

          trays_screens [screen_number].icon_table = g_hash_table_new (NULL,
                                                                       NULL);
        }
      else
        {
          g_printerr ("System tray didn't get the system tray manager selection for screen %d\n",
		      screen_number);
          g_object_unref (tray_manager);
        }
    }

  priv->trays_screen = &trays_screens [screen_number];
  trays_screens [screen_number].all_trays = g_slist_append (trays_screens [screen_number].all_trays,
                                                            tray);

  update_size_and_orientation (tray);

  return object;
}

static void
na_tray_dispose (GObject *object)
{
  NaTray *tray = NA_TRAY (object);
  NaTrayPrivate *priv = tray->priv;
  TraysScreen *trays_screen = priv->trays_screen;

  if (trays_screen != NULL)
    {
      trays_screen->all_trays = g_slist_remove (trays_screen->all_trays, tray);

      if (trays_screen->all_trays == NULL)
        {
          /* Make sure we drop the manager selection */
          g_object_unref (trays_screen->tray_manager);
          trays_screen->tray_manager = NULL;

          g_hash_table_destroy (trays_screen->icon_table);
          trays_screen->icon_table = NULL;

          g_hash_table_destroy (trays_screen->tip_table);
          trays_screen->tip_table = NULL;
        }
      else
        {
          NaTray *new_tray;

          new_tray = get_tray (trays_screen);
          if (new_tray != NULL)
            na_tray_manager_set_orientation (trays_screen->tray_manager,
                                             gtk_orientable_get_orientation (GTK_ORIENTABLE (new_tray)));
        }
    }

  priv->trays_screen = NULL;

  if (priv->idle_redraw_id != 0)
    {
      g_source_remove (priv->idle_redraw_id);
      priv->idle_redraw_id = 0;
    }

  G_OBJECT_CLASS (na_tray_parent_class)->dispose (object);
}

static void
na_tray_set_orientation (NaTray         *tray,
			 GtkOrientation  orientation)
{
  NaTrayPrivate *priv = tray->priv;

  if (orientation == priv->orientation)
    return;

  priv->orientation = orientation;

  update_size_and_orientation (tray);
}

static void
na_tray_set_property (GObject      *object,
		      guint         prop_id,
		      const GValue *value,
		      GParamSpec   *pspec)
{
  NaTray *tray = NA_TRAY (object);
  NaTrayPrivate *priv = tray->priv;

  switch (prop_id)
    {
    case PROP_ORIENTATION:
      na_tray_set_orientation (tray, g_value_get_enum (value));
      break;
    case PROP_ICON_PADDING:
      na_tray_set_padding (tray, g_value_get_int (value));
      break;
    case PROP_ICON_SIZE:
      na_tray_set_icon_size (tray, g_value_get_int (value));
      break;
    case PROP_SCREEN:
      priv->screen = g_value_get_object (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
na_tray_get_property (GObject    *object,
		      guint       prop_id,
		      GValue     *value,
		      GParamSpec *pspec)
{
  NaTray *tray = NA_TRAY (object);
  NaTrayPrivate *priv = tray->priv;

  switch (prop_id)
    {
    case PROP_ORIENTATION:
      g_value_set_enum (value, tray->priv->orientation);
      break;
    case PROP_ICON_PADDING:
      g_value_set_int (value, tray->priv->icon_padding);
      break;
    case PROP_ICON_SIZE:
      g_value_set_int (value, tray->priv->icon_size);
      break;
    case PROP_SCREEN:
      g_value_set_object (value, priv->screen);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
na_tray_class_init (NaTrayClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->constructor = na_tray_constructor;
  gobject_class->set_property = na_tray_set_property;
  gobject_class->get_property = na_tray_get_property;
  gobject_class->dispose = na_tray_dispose;

  g_object_class_override_property (gobject_class, PROP_ORIENTATION, "orientation");

  g_object_class_override_property (gobject_class, PROP_ICON_PADDING, "icon-padding");
  g_object_class_override_property (gobject_class, PROP_ICON_SIZE, "icon-size");

  g_object_class_install_property
    (gobject_class,
     PROP_SCREEN,
     g_param_spec_object ("screen", "screen", "screen",
			  GDK_TYPE_SCREEN,
			  G_PARAM_WRITABLE |
			  G_PARAM_CONSTRUCT_ONLY |
			  G_PARAM_STATIC_NAME |
			  G_PARAM_STATIC_NICK |
			  G_PARAM_STATIC_BLURB));

  g_type_class_add_private (gobject_class, sizeof (NaTrayPrivate));
}

NaHost *
na_tray_new_for_screen (GdkScreen      *screen,
		        GtkOrientation  orientation)
{
  return g_object_new (NA_TYPE_TRAY,
		       "screen", screen,
		       "orientation", orientation,
		       NULL);
}

void
na_tray_set_padding (NaTray *tray,
                     gint    padding)
{
  NaTrayPrivate *priv = tray->priv;

  priv->icon_padding = padding;
  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_padding (priv->trays_screen->tray_manager, padding);
}

void
na_tray_set_icon_size (NaTray *tray,
                       gint    size)
{
  NaTrayPrivate *priv = tray->priv;

  priv->icon_size = size;
  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_icon_size (priv->trays_screen->tray_manager, size);
}

static void
na_tray_set_colors (NaTray   *tray,
                    GdkRGBA  *fg,
                    GdkRGBA  *error,
                    GdkRGBA  *warning,
                    GdkRGBA  *success)
{
  NaTrayPrivate *priv = tray->priv;

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_colors (priv->trays_screen->tray_manager, fg, error, warning, success);
}

static void
na_tray_style_updated (NaHost          *host,
                       GtkStyleContext *context)
{
  GdkRGBA fg;
  GdkRGBA error;
  GdkRGBA warning;
  GdkRGBA success;

  gtk_style_context_save (context);
  gtk_style_context_set_state (context, GTK_STATE_FLAG_NORMAL);

  gtk_style_context_get_color (context, GTK_STATE_FLAG_NORMAL, &fg);

  if (!gtk_style_context_lookup_color (context, "error_color", &error))
    error = fg;
  if (!gtk_style_context_lookup_color (context, "warning_color", &warning))
    warning = fg;
  if (!gtk_style_context_lookup_color (context, "success_color", &success))
    success = fg;

  gtk_style_context_restore (context);

  na_tray_set_colors (NA_TRAY (host), &fg, &error, &warning, &success);
}

static gboolean
idle_redraw_cb (NaTray *tray)
{
  NaTrayPrivate *priv = tray->priv;

  g_hash_table_foreach (priv->trays_screen->icon_table,
                        (GHFunc) na_tray_child_force_redraw, NULL);

  priv->idle_redraw_id = 0;

  return FALSE;
}

static void
na_tray_force_redraw (NaHost *host)
{
  NaTray *tray = NA_TRAY (host);
  NaTrayPrivate *priv = tray->priv;

  /* Force the icons to redraw their backgrounds.
   */
  if (priv->idle_redraw_id == 0)
    priv->idle_redraw_id = g_idle_add ((GSourceFunc) idle_redraw_cb, tray);
}
