/* na-tray-child.c
 * Copyright (C) 2002 Anders Carlsson <andersca@gnu.org>
 * Copyright (C) 2003-2006 Vincent Untz
 * Copyright (C) 2008 Red Hat, Inc.
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
 */

#include <config.h>
#include <string.h>

#include "na-tray-child.h"

#include <glib/gi18n.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>

#include "na-item.h"

enum
{
  PROP_0,
  PROP_ORIENTATION
};

static void na_item_init (NaItemInterface *iface);

G_DEFINE_TYPE_WITH_CODE (NaTrayChild, na_tray_child, GTK_TYPE_SOCKET,
                         G_IMPLEMENT_INTERFACE (GTK_TYPE_ORIENTABLE, NULL)
                         G_IMPLEMENT_INTERFACE (NA_TYPE_ITEM, na_item_init))

static void
na_tray_child_finalize (GObject *object)
{
  NaTrayChild *child = NA_TRAY_CHILD (object);

  g_clear_pointer (&child->id, g_free);

  G_OBJECT_CLASS (na_tray_child_parent_class)->finalize (object);
}

static void
na_tray_child_realize (GtkWidget *widget)
{
  NaTrayChild *child = NA_TRAY_CHILD (widget);
  GdkVisual *visual = gtk_widget_get_visual (widget);
  GdkWindow *window;

  GTK_WIDGET_CLASS (na_tray_child_parent_class)->realize (widget);

  window = gtk_widget_get_window (widget);

  if (child->has_alpha)
    {
      /* We have real transparency with an ARGB visual and the Composite
       * extension. */

      /* Set a transparent background */
      cairo_pattern_t *transparent = cairo_pattern_create_rgba (0, 0, 0, 0);
      gdk_window_set_background_pattern (window, transparent);
      gdk_window_set_composited (window, TRUE);
      cairo_pattern_destroy (transparent);

      child->parent_relative_bg = FALSE;
    }
  else if (visual == gdk_window_get_visual(gdk_window_get_parent(window)))
    {
      /* Otherwise, if the visual matches the visual of the parent window, we
       * can use a parent-relative background and fake transparency. */
      gdk_window_set_background_pattern (window, NULL);

      child->parent_relative_bg = TRUE;
    }
  else
    {
      /* Nothing to do; the icon will sit on top of an ugly gray box */
      child->parent_relative_bg = FALSE;
    }

  gdk_window_set_composited (window, child->composited);

  gtk_widget_set_app_paintable (GTK_WIDGET (child),
                                child->parent_relative_bg || child->has_alpha);
}

static void
na_tray_child_style_set (GtkWidget *widget,
                         GtkStyle  *previous_style)
{
  /* The default handler resets the background according to the new style.
   * We either use a transparent background or a parent-relative background
   * and ignore the style background. So, just don't chain up.
   */
}

#if !GTK_CHECK_VERSION (3, 23, 0)
static void
na_tray_child_get_preferred_width (GtkWidget *widget,
                                   gint      *minimal_width,
                                   gint      *natural_width)
{
  gint scale;
  scale = gtk_widget_get_scale_factor (widget);
  GTK_WIDGET_CLASS (na_tray_child_parent_class)->get_preferred_width (widget,
                                                                      minimal_width,
                                                                      natural_width);

  if (*minimal_width < 16)
    *minimal_width = 16;

  if (*natural_width < 16)
    *natural_width = 16;

  *minimal_width = *minimal_width / scale;
  *natural_width = *natural_width / scale;
}

static void
na_tray_child_get_preferred_height (GtkWidget *widget,
                                    gint      *minimal_height,
                                    gint      *natural_height)
{
  gint scale;
  scale = gtk_widget_get_scale_factor (widget);
  GTK_WIDGET_CLASS (na_tray_child_parent_class)->get_preferred_height (widget,
                                                                       minimal_height,
                                                                       natural_height);

  if (*minimal_height < 16)
    *minimal_height = 16;

  if (*natural_height < 16)
    *natural_height = 16;

  *minimal_height = *minimal_height / scale;
  *natural_height = *natural_height / scale;
}
#endif

/* The plug window should completely occupy the area of the child, so we won't
 * get an expose event. But in case we do (the plug unmaps itself, say), this
 * expose handler draws with real or fake transparency.
 */
static gboolean
na_tray_child_draw (GtkWidget *widget,
                    cairo_t *cr)
{
  NaTrayChild *child = NA_TRAY_CHILD (widget);

  if (na_tray_child_has_alpha (child))
    {
      /* Clear to transparent */
      cairo_set_source_rgba (cr, 0, 0, 0, 0);
      cairo_set_operator (cr, CAIRO_OPERATOR_SOURCE);
      cairo_paint (cr);
    }
  else if (child->parent_relative_bg)
    {
      /* Clear to parent-relative pixmap */
      GdkWindow *window;
      cairo_surface_t *target;
      GdkRectangle clip_rect;

      window = gtk_widget_get_window (widget);
      target = cairo_get_group_target (cr);

      gdk_cairo_get_clip_rectangle (cr, &clip_rect);

      /* Clear to parent-relative pixmap
       * We need to use direct X access here because GDK doesn't know about
       * the parent relative pixmap. */
      cairo_surface_flush (target);

      XClearArea (GDK_WINDOW_XDISPLAY (window),
                  GDK_WINDOW_XID (window),
                  clip_rect.x, clip_rect.y,
                  clip_rect.width, clip_rect.height,
                  False);
      cairo_surface_mark_dirty_rectangle (target,
                                          clip_rect.x, clip_rect.y,
                                          clip_rect.width, clip_rect.height);
    }

  return FALSE;
}

/* Children with alpha channels have been set to be composited by calling
 * gdk_window_set_composited(). We need to paint these children ourselves.
 *
 * FIXME: is that still needed on GTK3?  Seems like it could be done in draw().
 */
static gboolean
na_tray_child_draw_on_parent (NaItem    *item,
                              GtkWidget *parent,
                              cairo_t   *parent_cr)
{
  if (na_tray_child_has_alpha (NA_TRAY_CHILD (item)))
    {
      GtkWidget    *widget = GTK_WIDGET (item);
      GtkAllocation parent_allocation = { 0 };
      GtkAllocation allocation;

      /* if the parent doesn't have a window, our allocation is not relative to
       * the context coordinates but to the parent's allocation */
      if (! gtk_widget_get_has_window (parent))
	gtk_widget_get_allocation (parent, &parent_allocation);

      gtk_widget_get_allocation (widget, &allocation);
      allocation.x -= parent_allocation.x;
      allocation.y -= parent_allocation.y;

      cairo_save (parent_cr);
      gdk_cairo_set_source_window (parent_cr,
                                   gtk_widget_get_window (widget),
                                   allocation.x,
                                   allocation.y);
      cairo_rectangle (parent_cr, allocation.x, allocation.y, allocation.width, allocation.height);
      cairo_clip (parent_cr);
      cairo_paint (parent_cr);
      cairo_restore (parent_cr);
    }

  return TRUE;
}

static void
na_tray_child_get_property (GObject    *object,
                            guint       property_id,
                            GValue     *value,
                            GParamSpec *pspec)
{
  switch (property_id)
    {
      case PROP_ORIENTATION:
        /* whatever */
        g_value_set_enum (value, GTK_ORIENTATION_HORIZONTAL);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
na_tray_child_set_property (GObject      *object,
                            guint         property_id,
                            const GValue *value,
                            GParamSpec   *pspec)
{
  switch (property_id)
    {
      case PROP_ORIENTATION:
	/* we so don't care */
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

/* Hack to keep order of some known system-tray elements.  For a wm_class
 * match, give it category @category and ID @id.
 *
 * TODO: improve this to play well if one of those elements were to start
 *       using SNI instead */
static const struct
{
  const gchar *const wm_class;
  const gchar *const id;
  NaItemCategory category;
} wmclass_categories[] = {
  /* order is LTR, so higher category and higher ASCII ordering on the right */
  { "keyboard",                   "~01-keyboard",  NA_ITEM_CATEGORY_HARDWARE },
  { "Mate-volume-control-applet", "~02-volume",    NA_ITEM_CATEGORY_HARDWARE },
  { "Bluetooth-applet",           "~03-bluetooth", NA_ITEM_CATEGORY_HARDWARE },
  { "Nm-applet",                  "~04-network",   NA_ITEM_CATEGORY_HARDWARE },
  { "Mate-power-manager",         "~05-battery",   NA_ITEM_CATEGORY_HARDWARE },
};

static const gchar *
na_tray_child_get_id (NaItem *item)
{
  NaTrayChild *child = NA_TRAY_CHILD (item);

  if (! child->id)
    {
      char *res_name = NULL;
      char *res_class = NULL;
      guint i;

      na_tray_child_get_wm_class (child, &res_name, &res_class);

      for (i = 0; i < G_N_ELEMENTS (wmclass_categories) && ! child->id; i++)
	{
	  if (g_strcmp0 (res_class, wmclass_categories[i].wm_class) == 0)
	    child->id = g_strdup (wmclass_categories[i].id);
	}

      if (! child->id)
	child->id = res_name;
      else
	g_free (res_name);

      g_free (res_class);
    }

  return child->id;
}

static NaItemCategory
na_tray_child_get_category (NaItem *item)
{
  guint i;
  NaItemCategory category = NA_ITEM_CATEGORY_APPLICATION_STATUS;
  char *res_class = NULL;

  na_tray_child_get_wm_class (NA_TRAY_CHILD (item), NULL, &res_class);

  for (i = 0; i < G_N_ELEMENTS (wmclass_categories); i++)
    {
      if (g_strcmp0 (res_class, wmclass_categories[i].wm_class) == 0)
	{
	  category = wmclass_categories[i].category;
	  break;
	}
    }

  g_free (res_class);

  return category;
}

static void
na_item_init (NaItemInterface *iface)
{
  iface->get_id = na_tray_child_get_id;
  iface->get_category = na_tray_child_get_category;

  iface->draw_on_parent = na_tray_child_draw_on_parent;
}

static void
na_tray_child_init (NaTrayChild *child)
{
  child->id = NULL;
}

static void
na_tray_child_class_init (NaTrayChildClass *klass)
{
  GObjectClass *gobject_class;
  GtkWidgetClass *widget_class;

  gobject_class = (GObjectClass *)klass;
  widget_class = (GtkWidgetClass *)klass;

  gobject_class->finalize = na_tray_child_finalize;
  gobject_class->get_property = na_tray_child_get_property;
  gobject_class->set_property = na_tray_child_set_property;

  widget_class->style_set = na_tray_child_style_set;
  widget_class->realize = na_tray_child_realize;
#if !GTK_CHECK_VERSION (3, 23, 0)
  widget_class->get_preferred_width = na_tray_child_get_preferred_width;
  widget_class->get_preferred_height = na_tray_child_get_preferred_height;
#endif
  widget_class->draw = na_tray_child_draw;

  /* we don't really care actually */
  g_object_class_override_property (gobject_class, PROP_ORIENTATION, "orientation");
}

GtkWidget *
na_tray_child_new (GdkScreen *screen,
                   Window     icon_window)
{
  XWindowAttributes window_attributes;
  Display *xdisplay;
  GdkDisplay *display;
  NaTrayChild *child;
  GdkVisual *visual;
  gboolean visual_has_alpha;
  int red_prec, green_prec, blue_prec, depth;
  int result;

  g_return_val_if_fail (GDK_IS_SCREEN (screen), NULL);
  g_return_val_if_fail (icon_window != None, NULL);

  xdisplay = GDK_SCREEN_XDISPLAY (screen);

  /* We need to determine the visual of the window we are embedding and create
   * the socket in the same visual.
   */

  display = gdk_screen_get_display (screen);
  if (!GDK_IS_X11_DISPLAY (display)) {
    g_warning ("na_tray only works on X11");
    return NULL;
  }
  gdk_x11_display_error_trap_push (display);
  result = XGetWindowAttributes (xdisplay, icon_window,
                                 &window_attributes);
  gdk_x11_display_error_trap_pop_ignored (display);

  if (!result) /* Window already gone */
    return NULL;

  visual = gdk_x11_screen_lookup_visual (screen,
                                         window_attributes.visual->visualid);
  if (!visual) /* Icon window is on another screen? */
    return NULL;

  child = g_object_new (NA_TYPE_TRAY_CHILD, NULL);
  child->icon_window = icon_window;

  gtk_widget_set_visual (GTK_WIDGET (child), visual);

  /* We have alpha if the visual has something other than red, green,
   * and blue */
  gdk_visual_get_red_pixel_details (visual, NULL, NULL, &red_prec);
  gdk_visual_get_green_pixel_details (visual, NULL, NULL, &green_prec);
  gdk_visual_get_blue_pixel_details (visual, NULL, NULL, &blue_prec);
  depth = gdk_visual_get_depth (visual);

  visual_has_alpha = red_prec + blue_prec + green_prec < depth;
  child->has_alpha = (visual_has_alpha &&
                      gdk_display_supports_composite (gdk_screen_get_display (screen)));

  child->composited = child->has_alpha;

  return GTK_WIDGET (child);
}

char *
na_tray_child_get_title (NaTrayChild *child)
{
  char *retval = NULL;
  GdkDisplay *display;
  Atom utf8_string, atom, type;
  int result;
  int format;
  gulong nitems;
  gulong bytes_after;
  gchar *val;

  g_return_val_if_fail (NA_IS_TRAY_CHILD (child), NULL);

  display = gtk_widget_get_display (GTK_WIDGET (child));

  utf8_string = gdk_x11_get_xatom_by_name_for_display (display, "UTF8_STRING");
  atom = gdk_x11_get_xatom_by_name_for_display (display, "_NET_WM_NAME");

  gdk_x11_display_error_trap_push (display);

  result = XGetWindowProperty (GDK_DISPLAY_XDISPLAY (display),
                               child->icon_window,
                               atom,
                               0, G_MAXLONG,
                               False, utf8_string,
                               &type, &format, &nitems,
                               &bytes_after, (guchar **)&val);

  if (gdk_x11_display_error_trap_pop (display) || result != Success)
    return NULL;

  if (type != utf8_string ||
      format != 8 ||
      nitems == 0)
    {
      if (val)
        XFree (val);
      return NULL;
    }

  if (!g_utf8_validate (val, nitems, NULL))
    {
      XFree (val);
      return NULL;
    }

  retval = g_strndup (val, nitems);

  XFree (val);

  return retval;
}

/**
 * na_tray_child_has_alpha;
 * @child: a #NaTrayChild
 *
 * Checks if the child has an ARGB visual and real alpha transparence.
 * (as opposed to faked alpha transparency with an parent-relative
 * background)
 *
 * Return value: %TRUE if the child has an alpha transparency
 */
gboolean
na_tray_child_has_alpha (NaTrayChild *child)
{
  g_return_val_if_fail (NA_IS_TRAY_CHILD (child), FALSE);

  return child->has_alpha;
}

/**
 * na_tray_child_set_composited;
 * @child: a #NaTrayChild
 * @composited: %TRUE if the child's window should be redirected
 *
 * Sets whether the #GdkWindow of the child should be set redirected
 * using gdk_window_set_composited(). By default this is based off of
 * na_tray_child_has_alpha(), but it may be useful to override it in
 * certain circumstances; for example, if the #NaTrayChild is added
 * to a parent window and that parent window is composited against the
 * background.
 */
void
na_tray_child_set_composited (NaTrayChild *child,
                              gboolean     composited)
{
  g_return_if_fail (NA_IS_TRAY_CHILD (child));

  if (child->composited == composited)
    return;

  child->composited = composited;
  if (gtk_widget_get_realized (GTK_WIDGET (child)))
    gdk_window_set_composited (gtk_widget_get_window (GTK_WIDGET (child)),
                               composited);
}

/* If we are faking transparency with a window-relative background, force a
 * redraw of the icon. This should be called if the background changes or if
 * the child is shifted with respect to the background.
 */
void
na_tray_child_force_redraw (NaTrayChild *child)
{
  GtkWidget *widget = GTK_WIDGET (child);

  if (gtk_widget_get_mapped (widget))
    {
    /* Hiding and showing is the safe way to do it, but can result in more
     * flickering.
     */
    gtk_widget_hide(widget);
    gtk_widget_show_all(widget);
    }
}

/* from libwnck/xutils.c, comes as LGPLv2+ */
static char *
latin1_to_utf8 (const char *latin1)
{
  GString *str;
  const char *p;

  str = g_string_new (NULL);

  p = latin1;
  while (*p)
    {
      g_string_append_unichar (str, (gunichar) *p);
      ++p;
    }

  return g_string_free (str, FALSE);
}

/* derived from libwnck/xutils.c, comes as LGPLv2+ */
static void
_get_wmclass (Display *xdisplay,
              Window   xwindow,
              char   **res_class,
              char   **res_name)
{
  GdkDisplay *display;
  XClassHint ch;

  ch.res_name = NULL;
  ch.res_class = NULL;

  display = gdk_display_get_default ();
  gdk_x11_display_error_trap_push (display);
  XGetClassHint (xdisplay, xwindow, &ch);
  gdk_x11_display_error_trap_pop_ignored (display);

  if (res_class)
    *res_class = NULL;

  if (res_name)
    *res_name = NULL;

  if (ch.res_name)
    {
      if (res_name)
        *res_name = latin1_to_utf8 (ch.res_name);

      XFree (ch.res_name);
    }

  if (ch.res_class)
    {
      if (res_class)
        *res_class = latin1_to_utf8 (ch.res_class);

      XFree (ch.res_class);
    }
}

/**
 * na_tray_child_get_wm_class;
 * @child: a #NaTrayChild
 * @res_name: return location for a string containing the application name of
 * @child, or %NULL
 * @res_class: return location for a string containing the application class of
 * @child, or %NULL
 *
 * Fetches the resource associated with @child.
 */
void
na_tray_child_get_wm_class (NaTrayChild  *child,
                            char        **res_name,
                            char        **res_class)
{
  GdkDisplay *display;

  g_return_if_fail (NA_IS_TRAY_CHILD (child));

  display = gtk_widget_get_display (GTK_WIDGET (child));

  _get_wmclass (GDK_DISPLAY_XDISPLAY (display),
                child->icon_window,
                res_class,
                res_name);
}
