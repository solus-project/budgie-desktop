/*
 * Copyright (C) 2002 Red Hat, Inc.
 * Copyright (C) 2003-2006 Vincent Untz
 * Copyright (C) 2007 Christian Persch
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
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

#include <string.h>


#include <gtk/gtk.h>

#include "na-tray-manager.h"
#include "fixedtip.h"

#include "na-tray.h"

#define ICON_SPACING 1
#define MIN_BOX_SIZE 3

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

  GtkWidget *box;
  GtkWidget *frame;

  guint idle_redraw_id;

  GtkOrientation orientation;
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
  PROP_SCREEN
};

static gboolean     initialized   = FALSE;
static TraysScreen *trays_screens = NULL;

static void icon_tip_show_next (IconTip *icontip);

/* NaTray */

G_DEFINE_TYPE (NaTray, na_tray, GTK_TYPE_BIN)

static NaTray *
get_tray (TraysScreen *trays_screen)
{
  if (trays_screen->all_trays == NULL)
    return NULL;
  
  return trays_screen->all_trays->data;
}

const char *ordered_roles[] = {
  "keyboard",
  "volume",
  "bluetooth",
  "network",
  "battery",
  NULL
};

const char *wmclass_roles[] = {
  "Bluetooth-applet", "bluetooth",
  "Gnome-volume-control-applet", "volume",
  "Nm-applet", "network",
  "Gnome-power-manager", "battery",
  "keyboard", "keyboard",
  NULL,
};

static const char *
find_role (const char *wmclass)
{
  int i;

  for (i = 0; wmclass_roles[i]; i += 2)
    {
      if (strcmp (wmclass, wmclass_roles[i]) == 0)
        return wmclass_roles[i + 1];
    }

  return NULL;
}

static int
find_role_position (const char *role)
{
  int i;

  for (i = 0; ordered_roles[i]; i++)
    {
      if (strcmp (role, ordered_roles[i]) == 0)
        break;
    }

  return i + 1;
}

static int
find_icon_position (NaTray    *tray,
                    GtkWidget *icon)
{
  NaTrayPrivate *priv;
  int            position;
  char          *class_a;
  const char    *role;
  int            role_position;
  GList         *l, *children;

  /* We insert the icons with a known roles in a specific order (the one
   * defined by ordered_roles), and all other icons at the beginning of the box
   * (left in LTR). */

  priv = tray->priv;
  position = 0;

  class_a = NULL;
  na_tray_child_get_wm_class (NA_TRAY_CHILD (icon), NULL, &class_a);
  if (!class_a)
    return position;

  role = find_role (class_a);
  g_free (class_a);
  if (!role)
    return position;

  role_position = find_role_position (role);
  g_object_set_data (G_OBJECT (icon), "role-position", GINT_TO_POINTER (role_position));

  children = gtk_container_get_children (GTK_CONTAINER (priv->box));
  for (l = g_list_last (children); l; l = l->prev)
    {
      GtkWidget *child = l->data;
      int        rp;

      rp = GPOINTER_TO_INT (g_object_get_data (G_OBJECT (child), "role-position"));
      if (rp == 0 || rp < role_position)
        {
          position = g_list_index (children, child) + 1;
          break;
        }
    }
  g_list_free (children);

  /* should never happen, but it doesn't hurt to be on the safe side */
  if (position < 0)
    position = 0;

  return position;
}

static void
tray_added (NaTrayManager *manager,
            GtkWidget     *icon,
            TraysScreen   *trays_screen)
{
  NaTray *tray;
  NaTrayPrivate *priv;
  int position;

  tray = get_tray (trays_screen);
  if (tray == NULL)
    return;

  priv = tray->priv;

  g_assert (priv->trays_screen == trays_screen);

  g_hash_table_insert (trays_screen->icon_table, icon, tray);

  position = find_icon_position (tray, icon);
  gtk_box_pack_start (GTK_BOX (priv->box), icon, FALSE, FALSE, 0);
  gtk_box_reorder_child (GTK_BOX (priv->box), icon, position);

  gtk_widget_show (icon);
}

static void
tray_removed (NaTrayManager *manager,
              GtkWidget     *icon,
              TraysScreen   *trays_screen)
{
  NaTray *tray;
  NaTrayPrivate *priv;

  tray = g_hash_table_lookup (trays_screen->icon_table, icon);
  if (tray == NULL)
    return;

  priv = tray->priv;

  g_assert (tray->priv->trays_screen == trays_screen);

  gtk_container_remove (GTK_CONTAINER (priv->box), icon);

  g_hash_table_remove (trays_screen->icon_table, icon);
  /* this will also destroy the tip associated to this icon */
  g_hash_table_remove (trays_screen->tip_table, icon);
}

static void
icon_tip_buffer_free (gpointer data,
                      gpointer userdata)
{
  IconTipBuffer *buffer;

  buffer = data;

  g_free (buffer->text);
  buffer->text = NULL;

  g_free (buffer);
}

static void
icon_tip_free (gpointer data)
{
  IconTip *icontip;

  if (data == NULL)
    return;

  icontip = data;

  if (icontip->fixedtip != NULL)
    gtk_widget_destroy (GTK_WIDGET (icontip->fixedtip));
  icontip->fixedtip = NULL;

  if (icontip->source_id != 0)
    g_source_remove (icontip->source_id);
  icontip->source_id = 0;

  if (icontip->buffer != NULL)
    {
      g_slist_foreach (icontip->buffer, icon_tip_buffer_free, NULL);
      g_slist_free (icontip->buffer);
    }
  icontip->buffer = NULL;

  g_free (icontip);
}

static int
icon_tip_buffer_compare (gconstpointer a,
                         gconstpointer b)
{
  const IconTipBuffer *buffer_a = a;
  const IconTipBuffer *buffer_b = b;

  if (buffer_a == NULL || buffer_b == NULL)
    return !(buffer_a == buffer_b);

  return buffer_a->id - buffer_b->id;
}

static void
icon_tip_show_next_clicked (GtkWidget *widget,
                            gpointer   data)
{
  icon_tip_show_next ((IconTip *) data);
}

static gboolean
icon_tip_show_next_timeout (gpointer data)
{
  IconTip *icontip = (IconTip *) data;

  icon_tip_show_next (icontip);

  return FALSE;
}

static void
icon_tip_show_next (IconTip *icontip)
{
  IconTipBuffer *buffer;

  if (icontip->buffer == NULL)
    {
      /* this will also destroy the tip window */
      g_hash_table_remove (icontip->tray->priv->trays_screen->tip_table,
                           icontip->icon);
      return;
    }

  if (icontip->source_id != 0)
    g_source_remove (icontip->source_id);
  icontip->source_id = 0;

  buffer = icontip->buffer->data;
  icontip->buffer = g_slist_remove (icontip->buffer, buffer);

  if (icontip->fixedtip == NULL)
    {
      icontip->fixedtip = na_fixed_tip_new (icontip->icon,
                                            na_tray_get_orientation (icontip->tray));

      g_signal_connect (icontip->fixedtip, "clicked",
                        G_CALLBACK (icon_tip_show_next_clicked), icontip);
    }

  na_fixed_tip_set_markup (icontip->fixedtip, buffer->text);

  if (!gtk_widget_get_mapped (icontip->fixedtip))
    gtk_widget_show (icontip->fixedtip);

  icontip->id = buffer->id;

  if (buffer->timeout > 0)
    icontip->source_id = g_timeout_add_seconds (buffer->timeout,
                                                icon_tip_show_next_timeout,
                                                icontip);

  icon_tip_buffer_free (buffer, NULL);
}

static void
message_sent (NaTrayManager *manager,
              GtkWidget     *icon,
              const char    *text,
              glong          id,
              glong          timeout,
              TraysScreen   *trays_screen)
{
  IconTip       *icontip;
  IconTipBuffer  find_buffer;
  IconTipBuffer *buffer;
  gboolean       show_now;

  icontip = g_hash_table_lookup (trays_screen->tip_table, icon);

  find_buffer.id = id;
  if (icontip && 
      (icontip->id == id ||
       g_slist_find_custom (icontip->buffer, &find_buffer,
                            icon_tip_buffer_compare) != NULL))
    /* we already have this message, so ignore it */
    /* FIXME: in an ideal world, we'd remember all the past ids and ignore them
     * too */
    return;

  show_now = FALSE;

  if (icontip == NULL)
    {
      NaTray *tray;

      tray = g_hash_table_lookup (trays_screen->icon_table, icon);
      if (tray == NULL)
        {
          /* We don't know about the icon sending the message, so ignore it.
           * But this should never happen since NaTrayManager shouldn't send
           * us the message if there's no socket for it. */
          g_critical ("Ignoring a message sent by a tray icon "
                      "we don't know: \"%s\".\n", text);
          return;
        }

      icontip = g_new0 (IconTip, 1);
      icontip->tray = tray;
      icontip->icon = icon;

      g_hash_table_insert (trays_screen->tip_table, icon, icontip);

      show_now = TRUE;
    }

  buffer = g_new0 (IconTipBuffer, 1);

  buffer->text    = g_strdup (text);
  buffer->id      = id;
  buffer->timeout = timeout;

  icontip->buffer = g_slist_append (icontip->buffer, buffer);

  if (show_now)
    icon_tip_show_next (icontip);
}

static void
message_cancelled (NaTrayManager *manager,
                   GtkWidget     *icon,
                   glong          id,
                   TraysScreen   *trays_screen)
{
  IconTip       *icontip;
  IconTipBuffer  find_buffer;
  GSList        *cancel_buffer_l;
  IconTipBuffer *cancel_buffer;

  icontip = g_hash_table_lookup (trays_screen->tip_table, icon);
  if (icontip == NULL)
    return;

  if (icontip->id == id)
    {
      icon_tip_show_next (icontip);
      return;
    }

  find_buffer.id = id;
  cancel_buffer_l = g_slist_find_custom (icontip->buffer, &find_buffer,
                                         icon_tip_buffer_compare);
  if (cancel_buffer_l == NULL)
    return;

  cancel_buffer = cancel_buffer_l->data;
  icon_tip_buffer_free (cancel_buffer, NULL);

  icontip->buffer = g_slist_remove_link (icontip->buffer, cancel_buffer_l);
  g_slist_free_1 (cancel_buffer_l);
}

static void
update_orientation_for_messages (gpointer key,
                                 gpointer value,
                                 gpointer data)
{
  NaTray *tray;
  IconTip    *icontip;

  if (value == NULL)
    return;

  icontip = value;
  tray    = data;
  if (icontip->tray != tray)
    return;

  if (icontip->fixedtip)
    na_fixed_tip_set_orientation (icontip->fixedtip, tray->priv->orientation);
}

static void
update_size_and_orientation (NaTray *tray)
{
  NaTrayPrivate *priv = tray->priv;

  gtk_orientable_set_orientation (GTK_ORIENTABLE (priv->box), priv->orientation);

  /* This only happens when setting the property during object construction */
  if (!priv->trays_screen)
    return;

  g_hash_table_foreach (priv->trays_screen->tip_table,
                        update_orientation_for_messages, tray);

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_orientation (priv->trays_screen->tray_manager,
                                     priv->orientation);

  /* note, you want this larger if the frame has non-NONE relief by default. */
  switch (priv->orientation)
    {
    case GTK_ORIENTATION_VERTICAL:
      /* Give box a min size so the frame doesn't look dumb */
      gtk_widget_set_size_request (priv->box, MIN_BOX_SIZE, -1);
      break;
    case GTK_ORIENTATION_HORIZONTAL:
      gtk_widget_set_size_request (priv->box, -1, MIN_BOX_SIZE);
      break;
    }
}

/* Children with alpha channels have been set to be composited by calling
 * gdk_window_set_composited(). We need to paint these children ourselves.
 */
static void
na_tray_draw_icon (GtkWidget *widget,
		   gpointer   data)
{
  cairo_t *cr = (cairo_t *) data;

  if (na_tray_child_has_alpha (NA_TRAY_CHILD (widget)))
    {
      GtkAllocation allocation;

      gtk_widget_get_allocation (widget, &allocation);

      cairo_save (cr);
      gdk_cairo_set_source_window (cr,
                                   gtk_widget_get_window (widget),
				   allocation.x,
				   allocation.y);
      cairo_rectangle (cr, allocation.x, allocation.y, allocation.width, allocation.height);
      cairo_clip (cr);
      cairo_paint (cr);
      cairo_restore (cr);
    }
}

static void
na_tray_draw_box (GtkWidget *box,
		  cairo_t   *cr)
{
  gtk_container_foreach (GTK_CONTAINER (box), na_tray_draw_icon, cr);
}

static void
na_tray_init (NaTray *tray)
{
  NaTrayPrivate *priv;

  priv = tray->priv = G_TYPE_INSTANCE_GET_PRIVATE (tray, NA_TYPE_TRAY, NaTrayPrivate);

  priv->screen = NULL;
  priv->orientation = GTK_ORIENTATION_HORIZONTAL;

  priv->frame = gtk_alignment_new (0.5, 0.5, 1.0, 1.0);
  gtk_container_add (GTK_CONTAINER (tray), priv->frame);
  gtk_widget_show (priv->frame);

  priv->box = gtk_box_new (priv->orientation, ICON_SPACING);
  g_signal_connect (priv->box, "draw",
                    G_CALLBACK (na_tray_draw_box), NULL);
  gtk_container_add (GTK_CONTAINER (priv->frame), priv->box);
  gtk_widget_show (priv->box);
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
      GdkDisplay *display;
      int n_screens;

      display = gdk_display_get_default ();
      n_screens = gdk_display_get_n_screens (display);
      trays_screens = g_new0 (TraysScreen, n_screens);
      initialized = TRUE;
    }

  screen_number = gdk_screen_get_number (priv->screen);

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
          g_signal_connect (tray_manager, "message_sent",
                            G_CALLBACK (message_sent),
                            &trays_screens [screen_number]);
          g_signal_connect (tray_manager, "message_cancelled",
                            G_CALLBACK (message_cancelled),
                            &trays_screens [screen_number]);

          trays_screens [screen_number].icon_table = g_hash_table_new (NULL,
                                                                       NULL);
          trays_screens [screen_number].tip_table = g_hash_table_new_full (
                                                                NULL,
                                                                NULL,
                                                                NULL,
                                                                icon_tip_free);
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
                                             na_tray_get_orientation (new_tray));
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
    case PROP_SCREEN:
      priv->screen = g_value_get_object (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
na_tray_get_preferred_width (GtkWidget *widget,
                             gint      *minimal_width,
                             gint      *natural_width)
{
  gtk_widget_get_preferred_width (gtk_bin_get_child (GTK_BIN (widget)),
                                  minimal_width,
                                  natural_width);
}

static void
na_tray_get_preferred_height (GtkWidget *widget,
                              gint      *minimal_height,
                              gint      *natural_height)
{
  gtk_widget_get_preferred_height (gtk_bin_get_child (GTK_BIN (widget)),
                                   minimal_height,
                                   natural_height);
}

static void
na_tray_size_allocate (GtkWidget        *widget,
                       GtkAllocation    *allocation)
{
  gtk_widget_size_allocate (gtk_bin_get_child (GTK_BIN (widget)), allocation);
  gtk_widget_set_allocation (widget, allocation);
}

static void
na_tray_class_init (NaTrayClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

  gobject_class->constructor = na_tray_constructor;
  gobject_class->set_property = na_tray_set_property;
  gobject_class->dispose = na_tray_dispose;
  widget_class->get_preferred_width = na_tray_get_preferred_width;
  widget_class->get_preferred_height = na_tray_get_preferred_height;
  widget_class->size_allocate = na_tray_size_allocate;

  g_object_class_install_property
    (gobject_class,
     PROP_ORIENTATION,
     g_param_spec_enum ("orientation", "orientation", "orientation",
		        GTK_TYPE_ORIENTATION,
			GTK_ORIENTATION_HORIZONTAL,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_NAME |
			G_PARAM_STATIC_NICK |
			G_PARAM_STATIC_BLURB));
  
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

NaTray *
na_tray_new_for_screen (GdkScreen      *screen,
		        GtkOrientation  orientation)
{
  return g_object_new (NA_TYPE_TRAY,
		       "screen", screen,
		       "orientation", orientation,
		       NULL);
}

void
na_tray_set_orientation (NaTray         *tray,
			 GtkOrientation  orientation)
{
  NaTrayPrivate *priv = tray->priv;

  if (orientation == priv->orientation)
    return;
  
  priv->orientation = orientation;

  update_size_and_orientation (tray);
}

GtkOrientation
na_tray_get_orientation (NaTray *tray)
{
  return tray->priv->orientation;
}

static gboolean
idle_redraw_cb (NaTray *tray)
{
  NaTrayPrivate *priv = tray->priv;

  gtk_container_foreach (GTK_CONTAINER (priv->box), (GtkCallback)na_tray_child_force_redraw, tray);
  
  priv->idle_redraw_id = 0;

  return FALSE;
}

void
na_tray_set_padding (NaTray *tray,
                     gint    padding)
{
  NaTrayPrivate *priv = tray->priv;

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_padding (priv->trays_screen->tray_manager, padding);
}

void
na_tray_set_icon_size (NaTray *tray,
                       gint    size)
{
  NaTrayPrivate *priv = tray->priv;

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_icon_size (priv->trays_screen->tray_manager, size);
}

void
na_tray_set_colors (NaTray   *tray,
                    GdkColor *fg,
                    GdkColor *error,
                    GdkColor *warning,
                    GdkColor *success)
{
  NaTrayPrivate *priv = tray->priv;

  if (get_tray (priv->trays_screen) == tray)
    na_tray_manager_set_colors (priv->trays_screen->tray_manager, fg, error, warning, success);
}

void
na_tray_force_redraw (NaTray *tray)
{
  NaTrayPrivate *priv = tray->priv;

  /* Force the icons to redraw their backgrounds.
   */
  if (priv->idle_redraw_id == 0)
    priv->idle_redraw_id = g_idle_add ((GSourceFunc) idle_redraw_cb, tray);
}
