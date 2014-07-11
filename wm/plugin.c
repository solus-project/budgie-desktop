/* -*- mode: C; c-file-style: "gnu"; indent-tabs-mode: nil; -*- */

/*
 * Copyright (c) 2008 Intel Corp.
 *
 * Author: Tomas Frydrych <tf@linux.intel.com>
 * 
 * Adapted for budgie-wm by Ikey Doherty <ikey.doherty@gmail.com>
 * Contributions can be checked with git log wm/plugin.c for new author
 * list. My contributions to this file remain external to my employment
 * and the GNOME project. They are here solely for the Evolve OS Budgie
 * Desktop.
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 */

#pragma GCC diagnostic ignored "-Wdeprecated"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
/* Because GCC is tripping about the bitfields */
#pragma GCC diagnostic ignored "-Woverflow"

#include <meta/meta-plugin.h>
#include <meta/window.h>
#include <meta/util.h>
#include <meta/meta-background.h>
#include <meta/meta-background-group.h>
#include <meta/meta-background-actor.h>
#include <meta/prefs.h>
#include <meta/keybindings.h>

#include <libintl.h>
#define _(x) dgettext (GETTEXT_PACKAGE, x)
#define N_(x) x

#include <clutter/clutter.h>
#include <gmodule.h>
#include <string.h>

#include "plugin.h"

#define DESTROY_TIMEOUT    100
#define DESTROY_SCALE      0.8
#define MINIMIZE_TIMEOUT   150
#define MAXIMIZE_TIMEOUT   100
#define MAP_TIMEOUT        110
#define MAP_SCALE          0.8
#define BACKGROUND_TIMEOUT 250
#define SWITCH_TIMEOUT     500

#define ACTOR_DATA_KEY "MCCP-Default-actor-data"


static GQuark actor_data_quark = 0;

static void start      (MetaPlugin      *plugin);
static void minimize   (MetaPlugin      *plugin,
                        MetaWindowActor *actor);
static void map        (MetaPlugin      *plugin,
                        MetaWindowActor *actor);
static void destroy    (MetaPlugin      *plugin,
                        MetaWindowActor *actor);
static void maximize   (MetaPlugin      *plugin,
                        MetaWindowActor *actor,
                        gint             x,
                        gint             y,
                        gint             width,
                        gint             height);
static void unmaximize (MetaPlugin      *plugin,
                        MetaWindowActor *actor,
                        gint             x,
                        gint             y,
                        gint             width,
                        gint             height);

static void switch_workspace (MetaPlugin          *plugin,
                              gint                 from,
                              gint                 to,
                              MetaMotionDirection  direction);

static void kill_window_effects   (MetaPlugin      *plugin,
                                   MetaWindowActor *actor);
static void kill_switch_workspace (MetaPlugin      *plugin);

static void confirm_display_change (MetaPlugin *plugin);

static const MetaPluginInfo * plugin_info (MetaPlugin *plugin);

static void
on_monitors_changed (MetaScreen *screen,
                     MetaPlugin *plugin);

static void settings_cb (GSettings *settings,
                         gchar *key,
                         gpointer userdata);


G_DEFINE_TYPE (MetaDefaultPlugin, meta_default_plugin, META_TYPE_PLUGIN)

/*META_PLUGIN_DECLARE(MetaDefaultPlugin, meta_default_plugin);*/

/*
 * Plugin private data that we store in the .plugin_private member.
 */
struct _MetaDefaultPluginPrivate
{
  /* Valid only when switch_workspace effect is in progress */
  ClutterTimeline       *tml_switch_workspace1;
  ClutterTimeline       *tml_switch_workspace2;
  ClutterActor          *desktop1;
  ClutterActor          *desktop2;

  ClutterActor          *background_group;
  GSettings             *settings;

  MetaPluginInfo         info;
};

/*
 * Per actor private data we attach to each actor.
 */
typedef struct _ActorPrivate
{
  ClutterActor *orig_parent;

  ClutterTimeline *tml_minimize;
  ClutterTimeline *tml_maximize;
  ClutterTimeline *tml_destroy;
  ClutterTimeline *tml_map;

  gboolean      is_minimized : 1;
  gboolean      is_maximized : 1;
} ActorPrivate;

/* callback data for when animations complete */
typedef struct
{
  ClutterActor *actor;
  MetaPlugin *plugin;
} EffectCompleteData;

/* Budgie specific callbacks */
void budgie_launch_menu (MetaDisplay    *display,
                         MetaScreen     *screen,
                         MetaWindow     *window,
                         XIDeviceEvent  *event,
                         MetaKeyBinding *binding,
                         gpointer        user_data)
{
  /* Ask budgie-panel to open the menu */
  g_spawn_command_line_async("budgie-panel --menu", NULL);
}

static void
meta_default_plugin_dispose (GObject *object)
{
  MetaDefaultPluginPrivate *priv = META_DEFAULT_PLUGIN (object)->priv;
  g_object_unref(priv->settings);
  G_OBJECT_CLASS (meta_default_plugin_parent_class)->dispose (object);
}

static void
meta_default_plugin_finalize (GObject *object)
{
  G_OBJECT_CLASS (meta_default_plugin_parent_class)->finalize (object);
}

static void
meta_default_plugin_set_property (GObject      *object,
			    guint         prop_id,
			    const GValue *value,
			    GParamSpec   *pspec)
{
  switch (prop_id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
meta_default_plugin_get_property (GObject    *object,
			    guint       prop_id,
			    GValue     *value,
			    GParamSpec *pspec)
{
  switch (prop_id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
meta_default_plugin_class_init (MetaDefaultPluginClass *klass)
{
  GObjectClass      *gobject_class = G_OBJECT_CLASS (klass);
  MetaPluginClass *plugin_class  = META_PLUGIN_CLASS (klass);

  gobject_class->finalize        = meta_default_plugin_finalize;
  gobject_class->dispose         = meta_default_plugin_dispose;
  gobject_class->set_property    = meta_default_plugin_set_property;
  gobject_class->get_property    = meta_default_plugin_get_property;

  plugin_class->start            = start;
  plugin_class->map              = map;
  plugin_class->minimize         = minimize;
  plugin_class->maximize         = maximize;
  plugin_class->unmaximize       = unmaximize;
  plugin_class->destroy          = destroy;
  plugin_class->switch_workspace = switch_workspace;
  plugin_class->plugin_info      = plugin_info;
  plugin_class->kill_window_effects   = kill_window_effects;
  plugin_class->kill_switch_workspace = kill_switch_workspace;
  plugin_class->confirm_display_change = confirm_display_change;

  g_type_class_add_private (gobject_class, sizeof (MetaDefaultPluginPrivate));
}

static void
meta_default_plugin_init (MetaDefaultPlugin *self)
{
  MetaDefaultPluginPrivate *priv;

  self->priv = priv = META_DEFAULT_PLUGIN_GET_PRIVATE (self);
  priv->settings = g_settings_new(BACKGROUND_SCHEMA);
  g_signal_connect(priv->settings, "changed", G_CALLBACK(settings_cb),
                   self);

  priv->info.name        = "Default Effects";
  priv->info.version     = "0.1";
  priv->info.author      = "Intel Corp.";
  priv->info.license     = "GPL";
  priv->info.description = "This is an example of a plugin implementation.";

  /* Override schemas for edge-tiling and attachment of modal dialogs to parent */
  meta_prefs_override_preference_schema(MUTTER_EDGE_TILING, BUDGIE_WM_SCHEMA);
  meta_prefs_override_preference_schema(MUTTER_MODAL_ATTACH, BUDGIE_WM_SCHEMA);
}

static void settings_cb (GSettings *settings,
                         gchar *key,
                         gpointer userdata)
{
  MetaPlugin *plugin = META_PLUGIN (userdata);
  MetaScreen *screen = meta_plugin_get_screen (plugin);

  /* Force the wallpapers to be re-fetched */
  on_monitors_changed (screen, plugin);
}

/*
 * Actor private data accessor
 */
static void
free_actor_private (gpointer data)
{
  if (G_LIKELY (data != NULL))
    g_slice_free (ActorPrivate, data);
}

static ActorPrivate *
get_actor_private (MetaWindowActor *actor)
{
  ActorPrivate *priv = g_object_get_qdata (G_OBJECT (actor), actor_data_quark);

  if (G_UNLIKELY (actor_data_quark == 0))
    actor_data_quark = g_quark_from_static_string (ACTOR_DATA_KEY);

  if (G_UNLIKELY (!priv))
    {
      priv = g_slice_new0 (ActorPrivate);

      g_object_set_qdata_full (G_OBJECT (actor),
                               actor_data_quark, priv,
                               free_actor_private);
    }

  return priv;
}

static void
on_switch_workspace_effect_complete (ClutterTimeline *timeline, gpointer data)
{
  MetaPlugin               *plugin  = META_PLUGIN (data);
  MetaDefaultPluginPrivate *priv = META_DEFAULT_PLUGIN (plugin)->priv;
  MetaScreen *screen = meta_plugin_get_screen (plugin);
  GList *l = meta_get_window_actors (screen);

  while (l)
    {
      ClutterActor *a = l->data;
      MetaWindowActor *window_actor = META_WINDOW_ACTOR (a);
      ActorPrivate *apriv = get_actor_private (window_actor);

      if (apriv->orig_parent)
        {
          clutter_actor_reparent (a, apriv->orig_parent);
          apriv->orig_parent = NULL;
        }

      l = l->next;
    }

  clutter_actor_destroy (priv->desktop1);
  clutter_actor_destroy (priv->desktop2);

  priv->tml_switch_workspace1 = NULL;
  priv->tml_switch_workspace2 = NULL;
  priv->desktop1 = NULL;
  priv->desktop2 = NULL;

  meta_plugin_switch_workspace_completed (plugin);
}

static gboolean
show_stage (MetaPlugin *plugin)
{
  MetaScreen *screen;
  ClutterActor *stage;

  screen = meta_plugin_get_screen (plugin);
  stage = meta_get_stage_for_screen (screen);

  clutter_actor_show (stage);

  /* Set up our own keybinding overrides */
  meta_keybindings_set_custom_handler(BUDGIE_KEYBINDING_MAIN_MENU,
                                      budgie_launch_menu, NULL, NULL);

  return FALSE;
}

static void
background_load_file_cb (GObject      *source_object,
                         GAsyncResult *res,
                         gpointer      user_data)
{
  gboolean r;
  GError *error = NULL;

  r = meta_background_load_file_finish (META_BACKGROUND (source_object), 
                                        res, 
                                        &error);

  if (!r)
  {
    g_warning ("%s", error->message);
    g_error_free (error);
  }
}

static void
on_monitors_changed (MetaScreen *screen,
                     MetaPlugin *plugin)
{
  MetaDefaultPlugin *self = META_DEFAULT_PLUGIN (plugin);
  __attribute__ ((unused)) ClutterAnimation *animation;
  int i, n;
  gchar *wallpaper = NULL;
  GFile *wallpaper_file = NULL;
  gchar *filename = NULL;
  GDesktopBackgroundStyle style;
  GDesktopBackgroundShading  shading_direction;
  ClutterColor primary_color;
  ClutterColor secondary_color;
  gboolean random_colour = FALSE;

  clutter_actor_destroy_all_children (self->priv->background_group);

  wallpaper = g_settings_get_string (self->priv->settings, PICTURE_URI_KEY);
  /* We don't currently support slideshows */
  if (!wallpaper || g_str_has_suffix(wallpaper, ".xml"))
    random_colour = TRUE;
  else {
    gchar *color_str;

    /* Shading direction*/
    shading_direction = g_settings_get_enum (self->priv->settings, COLOR_SHADING_TYPE_KEY);

    /* Primary color */
    color_str = g_settings_get_string (self->priv->settings, PRIMARY_COLOR_KEY);
    if (color_str)
    {
      clutter_color_from_string (&primary_color, color_str);
      g_free (color_str);
      color_str = NULL;
    }
      
    /* Secondary color */
    color_str = g_settings_get_string (self->priv->settings, SECONDARY_COLOR_KEY);
    if (color_str)
    {
      clutter_color_from_string (&secondary_color, color_str);
      g_free (color_str);
      color_str = NULL;
    }

    /* Picture options: "none", "wallpaper", "centered", "scaled", "stretched", "zoom", "spanned" */
    style = g_settings_get_enum (self->priv->settings, BACKGROUND_STYLE_KEY);

    wallpaper_file = g_file_new_for_uri(wallpaper);
    filename = g_file_get_path(wallpaper_file);
  }

  n = meta_screen_get_n_monitors (screen);

  for (i = 0; i < n; i++)
    {
      MetaBackground *content;
      MetaRectangle rect;
      ClutterActor *background;

      background = meta_background_actor_new ();

      content = meta_background_new (screen, 
                                     i, 
                                     META_BACKGROUND_EFFECTS_NONE);
      // Don't use rand() here, mesa calls srand() internally when
      // parsing the driconf XML, but it's nice if the colors are
      // reproducible.
      if (random_colour)
      {
        clutter_color_init (&primary_color,
          g_random_int () % 255,
          g_random_int () % 255,
          g_random_int () % 255,
          255);

        meta_background_load_color (content, &primary_color);
      } else {
        if (style == G_DESKTOP_BACKGROUND_STYLE_NONE ||
            g_str_has_suffix (filename, GNOME_COLOR_HACK))
        {
          if (shading_direction == G_DESKTOP_BACKGROUND_SHADING_SOLID)
            meta_background_load_color (content, &primary_color);
          else
            meta_background_load_gradient (content,
                                           shading_direction,
                                           &primary_color,
                                           &secondary_color);
        } else {
          /* Set the background */
          meta_background_load_file_async (content,
                                           filename,
                                           style,
                                           NULL, /*TODO use cancellable*/
                                           background_load_file_cb,
                                           self);
        }
      }

      clutter_actor_set_content (background, CLUTTER_CONTENT (content));
      g_object_unref (content);

      meta_screen_get_monitor_geometry (screen, i, &rect);

      clutter_actor_set_position (background, rect.x, rect.y);
      clutter_actor_set_size (background, rect.width, rect.height);
      clutter_actor_add_child (self->priv->background_group, background);
      clutter_actor_set_scale (background, 0.0, 0.0);
      clutter_actor_show (background);
      clutter_actor_set_pivot_point (background, 0.5, 0.5);

      /* Ease in the background using a scale effect */
      animation = clutter_actor_animate (background, CLUTTER_EASE_IN_SINE,
                                         BACKGROUND_TIMEOUT,
                                         "scale-x", 1.0,
                                         "scale-y", 1.0,
                                         NULL);
    }
    if (wallpaper_file)
      g_object_unref(wallpaper_file);
    g_free(wallpaper);
    g_free(filename);
}

static void
start (MetaPlugin *plugin)
{
  MetaDefaultPlugin *self = META_DEFAULT_PLUGIN (plugin);
  MetaScreen *screen = meta_plugin_get_screen (plugin);

  self->priv->background_group = meta_background_group_new ();
  clutter_actor_insert_child_below (meta_get_window_group_for_screen (screen),
                                    self->priv->background_group, NULL);

  g_signal_connect (screen, "monitors-changed",
                    G_CALLBACK (on_monitors_changed), plugin);
  on_monitors_changed (screen, plugin);

  meta_later_add (META_LATER_BEFORE_REDRAW,
                  (GSourceFunc) show_stage,
                  plugin,
                  NULL);
}

static void
switch_workspace (MetaPlugin *plugin,
                  gint from, gint to,
                  MetaMotionDirection direction)
{
  MetaScreen *screen;
  MetaDefaultPluginPrivate *priv = META_DEFAULT_PLUGIN (plugin)->priv;
  GList        *l;
  ClutterActor *workspace0  = clutter_group_new ();
  ClutterActor *workspace1  = clutter_group_new ();
  ClutterActor *stage;
  int           screen_width, screen_height;
  ClutterAnimation *animation;

  screen = meta_plugin_get_screen (plugin);
  stage = meta_get_stage_for_screen (screen);

  meta_screen_get_size (screen,
                        &screen_width,
                        &screen_height);

  clutter_actor_set_anchor_point (workspace1,
                                  screen_width,
                                  screen_height);
  clutter_actor_set_position (workspace1,
                              screen_width,
                              screen_height);

  clutter_actor_set_scale (workspace1, 0.0, 0.0);

  clutter_container_add_actor (CLUTTER_CONTAINER (stage), workspace1);
  clutter_container_add_actor (CLUTTER_CONTAINER (stage), workspace0);

  if (from == to)
    {
      meta_plugin_switch_workspace_completed (plugin);
      return;
    }

  l = g_list_last (meta_get_window_actors (screen));

  while (l)
    {
      MetaWindowActor *window_actor = l->data;
      MetaWindow *window = meta_window_actor_get_meta_window (window_actor);
      MetaWorkspace   *workspace;
      ActorPrivate    *apriv	    = get_actor_private (window_actor);
      ClutterActor    *actor	    = CLUTTER_ACTOR (window_actor);
      gint             win_workspace;

      workspace = meta_window_get_workspace (window);
      win_workspace = meta_workspace_index (workspace);

      if (win_workspace == to || win_workspace == from)
        {
          apriv->orig_parent = clutter_actor_get_parent (actor);

          clutter_actor_reparent (actor,
				  win_workspace == to ? workspace1 : workspace0);
          clutter_actor_show_all (actor);
          clutter_actor_raise_top (actor);
        }
      else if (win_workspace < 0)
        {
          /* Sticky window */
          apriv->orig_parent = NULL;
        }
      else
        {
          /* Window on some other desktop */
          clutter_actor_hide (actor);
          apriv->orig_parent = NULL;
        }

      l = l->prev;
    }

  priv->desktop1 = workspace0;
  priv->desktop2 = workspace1;

  animation = clutter_actor_animate (workspace0, CLUTTER_EASE_IN_SINE,
                                     SWITCH_TIMEOUT,
                                     "scale-x", 1.0,
                                     "scale-y", 1.0,
                                     NULL);
  priv->tml_switch_workspace1 = clutter_animation_get_timeline (animation);
  g_signal_connect (priv->tml_switch_workspace1,
                    "completed",
                    G_CALLBACK (on_switch_workspace_effect_complete),
                    plugin);

  animation = clutter_actor_animate (workspace1, CLUTTER_EASE_IN_SINE,
                                     SWITCH_TIMEOUT,
                                     "scale-x", 0.0,
                                     "scale-y", 0.0,
                                     NULL);
  priv->tml_switch_workspace2 = clutter_animation_get_timeline (animation);
}


/*
 * Minimize effect completion callback; this function restores actor state, and
 * calls the manager callback function.
 */
static void
on_minimize_effect_complete (ClutterTimeline *timeline, EffectCompleteData *data)
{
  /*
   * Must reverse the effect of the effect; must hide it first to ensure
   * that the restoration will not be visible.
   */
  MetaPlugin *plugin = data->plugin;
  ActorPrivate *apriv;
  MetaWindowActor *window_actor = META_WINDOW_ACTOR (data->actor);

  apriv = get_actor_private (META_WINDOW_ACTOR (data->actor));
  apriv->tml_minimize = NULL;

  clutter_actor_hide (data->actor);

  /* FIXME - we shouldn't assume the original scale, it should be saved
   * at the start of the effect */
  clutter_actor_set_scale (data->actor, 1.0, 1.0);
  clutter_actor_move_anchor_point_from_gravity (data->actor,
                                                CLUTTER_GRAVITY_NORTH_WEST);

  /* Now notify the manager that we are done with this effect */
  meta_plugin_minimize_completed (plugin, window_actor);

  g_free (data);
}

/*
 * Simple minimize handler: it applies a scale effect (which must be reversed on
 * completion).
 */
static void
minimize (MetaPlugin *plugin, MetaWindowActor *window_actor)
{
  MetaWindowType type;
  MetaRectangle icon_geometry;
  MetaWindow *meta_window = meta_window_actor_get_meta_window (window_actor);
  ClutterActor *actor  = CLUTTER_ACTOR (window_actor);


  type = meta_window_get_window_type (meta_window);

  if (!meta_window_get_icon_geometry(meta_window, &icon_geometry))
    {
      icon_geometry.x = 0;
      icon_geometry.y = 0;
    }

  if (type == META_WINDOW_NORMAL)
    {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);

      apriv->is_minimized = TRUE;

      clutter_actor_move_anchor_point_from_gravity (actor,
                                                    CLUTTER_GRAVITY_CENTER);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_IN_SINE,
                                         MINIMIZE_TIMEOUT,
                                         "scale-x", 0.0,
                                         "scale-y", 0.0,
                                         "x", (double)icon_geometry.x,
                                         "y", (double)icon_geometry.y,
                                         NULL);
      apriv->tml_minimize = clutter_animation_get_timeline (animation);
      data->plugin = plugin;
      data->actor = actor;
      g_signal_connect (apriv->tml_minimize, "completed",
                        G_CALLBACK (on_minimize_effect_complete),
                        data);

    }
  else
    meta_plugin_minimize_completed (plugin, window_actor);
}

/*
 * Minimize effect completion callback; this function restores actor state, and
 * calls the manager callback function.
 */
static void
on_maximize_effect_complete (ClutterTimeline *timeline, EffectCompleteData *data)
{
  /*
   * Must reverse the effect of the effect.
   */
  MetaPlugin *plugin = data->plugin;
  MetaWindowActor *window_actor = META_WINDOW_ACTOR (data->actor);
  ActorPrivate *apriv = get_actor_private (window_actor);

  apriv->tml_maximize = NULL;

  /* FIXME - don't assume the original scale was 1.0 */
  clutter_actor_set_scale (data->actor, 1.0, 1.0);
  clutter_actor_move_anchor_point_from_gravity (data->actor,
                                                CLUTTER_GRAVITY_NORTH_WEST);

  /* Now notify the manager that we are done with this effect */
  meta_plugin_maximize_completed (plugin, window_actor);

  g_free (data);
}

/*
 * The Nature of Maximize operation is such that it is difficult to do a visual
 * effect that would work well. Scaling, the obvious effect, does not work that
 * well, because at the end of the effect we end up with window content bigger
 * and differently laid out than in the real window; this is a proof concept.
 *
 * (Something like a sound would be more appropriate.)
 */
static void
maximize (MetaPlugin *plugin,
          MetaWindowActor *window_actor,
          gint end_x, gint end_y, gint end_width, gint end_height)
{
  MetaWindowType type;
  ClutterActor *actor = CLUTTER_ACTOR (window_actor);
  MetaWindow *meta_window = meta_window_actor_get_meta_window (window_actor);

  gdouble  scale_x    = 1.0;
  gdouble  scale_y    = 1.0;
  gfloat   anchor_x   = 0;
  gfloat   anchor_y   = 0;

  type = meta_window_get_window_type (meta_window);

  if (type == META_WINDOW_NORMAL)
    {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);
      gfloat width, height;
      gfloat x, y;

      apriv->is_maximized = TRUE;

      clutter_actor_get_size (actor, &width, &height);
      clutter_actor_get_position (actor, &x, &y);

      /*
       * Work out the scale and anchor point so that the window is expanding
       * smoothly into the target size.
       */
      scale_x = (gdouble)end_width / (gdouble) width;
      scale_y = (gdouble)end_height / (gdouble) height;

      anchor_x = (gdouble)(x - end_x)*(gdouble)width /
        ((gdouble)(end_width - width));
      anchor_y = (gdouble)(y - end_y)*(gdouble)height /
        ((gdouble)(end_height - height));

      clutter_actor_move_anchor_point (actor, anchor_x, anchor_y);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_IN_SINE,
                                         MAXIMIZE_TIMEOUT,
                                         "scale-x", scale_x,
                                         "scale-y", scale_y,
                                         NULL);
      apriv->tml_maximize = clutter_animation_get_timeline (animation);
      data->plugin = plugin;
      data->actor = actor;
      g_signal_connect (apriv->tml_maximize, "completed",
                        G_CALLBACK (on_maximize_effect_complete),
                        data);
      return;
    }

  meta_plugin_maximize_completed (plugin, window_actor);
}

/*
 * See comments on the maximize() function.
 *
 * (Just a skeleton code.)
 */
static void
unmaximize (MetaPlugin *plugin,
            MetaWindowActor *window_actor,
            gint end_x, gint end_y, gint end_width, gint end_height)
{
  MetaWindow *meta_window = meta_window_actor_get_meta_window (window_actor);
  MetaWindowType type = meta_window_get_window_type (meta_window);

  if (type == META_WINDOW_NORMAL)
    {
      ActorPrivate *apriv = get_actor_private (window_actor);

      apriv->is_maximized = FALSE;
    }

  /* Do this conditionally, if the effect requires completion callback. */
  meta_plugin_unmaximize_completed (plugin, window_actor);
}

static void
on_map_effect_complete (ClutterTimeline *timeline, EffectCompleteData *data)
{
  /*
   * Must reverse the effect of the effect.
   */
  MetaPlugin *plugin = data->plugin;
  MetaWindowActor  *window_actor = META_WINDOW_ACTOR (data->actor);
  ActorPrivate  *apriv = get_actor_private (window_actor);

  apriv->tml_map = NULL;

  clutter_actor_move_anchor_point_from_gravity (data->actor,
                                                CLUTTER_GRAVITY_NORTH_WEST);

  /* Now notify the manager that we are done with this effect */
  meta_plugin_map_completed (plugin, window_actor);

  g_free (data);
}

/*
 * Simple map handler: it applies a scale effect which must be reversed on
 * completion).
 */
static void
map (MetaPlugin *plugin, MetaWindowActor *window_actor)
{
  MetaWindowType type;
  ClutterActor *actor = CLUTTER_ACTOR (window_actor);
  MetaWindow *meta_window = meta_window_actor_get_meta_window (window_actor);

  type = meta_window_get_window_type (meta_window);

  if (type == META_WINDOW_NORMAL || type == META_WINDOW_DIALOG ||
      type == META_WINDOW_MODAL_DIALOG)
  {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);
      const gchar *wm_class;

      clutter_actor_move_anchor_point_from_gravity (actor,
                                                    CLUTTER_GRAVITY_CENTER);

      wm_class = meta_window_get_wm_class (meta_window);

      if (g_str_equal(wm_class, "budgie-popover"))
      {
              /* Handle budgie-popover somewhat differently */
              gfloat height, width;
              height = clutter_actor_get_height (actor);
              width = clutter_actor_get_height (actor);

              clutter_actor_set_size (actor, width, 0.0);
              clutter_actor_set_opacity (actor, 0);
              clutter_actor_show (actor);
              animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_IN_BOUNCE,
                                         MAP_TIMEOUT+30,
                                         "width", width,
                                         "height", height,
                                         "opacity", 255,
                                         NULL);
      } else {                      
              clutter_actor_set_scale (actor, MAP_SCALE, MAP_SCALE);
              clutter_actor_set_opacity (actor, 0);
              clutter_actor_show (actor);

              animation = clutter_actor_animate (actor,
                                                 CLUTTER_EASE_IN_SINE,
                                                 MAP_TIMEOUT,
                                                 "scale-x", 1.0,
                                                 "scale-y", 1.0,
                                                 "opacity", 255,
                                                 NULL);
      }
      apriv->tml_map = clutter_animation_get_timeline (animation);
      data->actor = actor;
      data->plugin = plugin;
      g_signal_connect (apriv->tml_map, "completed",
                        G_CALLBACK (on_map_effect_complete),
                        data);

      apriv->is_minimized = FALSE;

  } else if (type == META_WINDOW_DOCK)
  {
      /* For context menus (popup/dropdown) we fade the menu in */
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);

      clutter_actor_set_opacity (actor, 0);
      clutter_actor_show (actor);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_IN_SINE,
                                         MAP_TIMEOUT,
                                         "opacity", 255,
                                         NULL);
      apriv->tml_map = clutter_animation_get_timeline (animation);
      data->actor = actor;
      data->plugin = plugin;
      g_signal_connect (apriv->tml_map, "completed",
                        G_CALLBACK (on_map_effect_complete),
                        data);

      apriv->is_minimized = FALSE;
  } else
    meta_plugin_map_completed (plugin, window_actor);
}

/*
 * Destroy effect completion callback; this is a simple effect that requires no
 * further action than notifying the manager that the effect is completed.
 */
static void
on_destroy_effect_complete (ClutterTimeline *timeline, EffectCompleteData *data)
{
  MetaPlugin *plugin = data->plugin;
  MetaWindowActor *window_actor = META_WINDOW_ACTOR (data->actor);
  ActorPrivate *apriv = get_actor_private (window_actor);

  apriv->tml_destroy = NULL;

  meta_plugin_destroy_completed (plugin, window_actor);
}

/*
 * Simple TV-out like effect.
 */
static void
destroy (MetaPlugin *plugin, MetaWindowActor *window_actor)
{
  MetaWindowType type;
  ClutterActor *actor = CLUTTER_ACTOR (window_actor);
  MetaWindow *meta_window = meta_window_actor_get_meta_window (window_actor);

  type = meta_window_get_window_type (meta_window);

  if (type == META_WINDOW_NORMAL || type == META_WINDOW_DIALOG ||
      type == META_WINDOW_MODAL_DIALOG)
  {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);

      clutter_actor_move_anchor_point_from_gravity (actor,
                                                    CLUTTER_GRAVITY_CENTER);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_IN_SINE,
                                         DESTROY_TIMEOUT,
                                         "scale-x", DESTROY_SCALE,
                                         "scale-y", DESTROY_SCALE,
                                         "opacity", 0,
                                         NULL);
      apriv->tml_destroy = clutter_animation_get_timeline (animation);
      data->plugin = plugin;
      data->actor = actor;
      g_signal_connect (apriv->tml_destroy, "completed",
                        G_CALLBACK (on_destroy_effect_complete),
                        data);
    }
  else
    meta_plugin_destroy_completed (plugin, window_actor);
}

static void
kill_switch_workspace (MetaPlugin     *plugin)
{
  MetaDefaultPluginPrivate *priv = META_DEFAULT_PLUGIN (plugin)->priv;

  if (priv->tml_switch_workspace1)
    {
      clutter_timeline_stop (priv->tml_switch_workspace1);
      clutter_timeline_stop (priv->tml_switch_workspace2);
      g_signal_emit_by_name (priv->tml_switch_workspace1, "completed", NULL);
    }
}

static void
kill_window_effects (MetaPlugin      *plugin,
                     MetaWindowActor *window_actor)
{
  ActorPrivate *apriv;

  apriv = get_actor_private (window_actor);

  if (apriv->tml_minimize)
    {
      clutter_timeline_stop (apriv->tml_minimize);
      g_signal_emit_by_name (apriv->tml_minimize, "completed", NULL);
    }

  if (apriv->tml_maximize)
    {
      clutter_timeline_stop (apriv->tml_maximize);
      g_signal_emit_by_name (apriv->tml_maximize, "completed", NULL);
    }

  if (apriv->tml_map)
    {
      clutter_timeline_stop (apriv->tml_map);
      g_signal_emit_by_name (apriv->tml_map, "completed", NULL);
    }

  if (apriv->tml_destroy)
    {
      clutter_timeline_stop (apriv->tml_destroy);
      g_signal_emit_by_name (apriv->tml_destroy, "completed", NULL);
    }
}

static const MetaPluginInfo *
plugin_info (MetaPlugin *plugin)
{
  MetaDefaultPluginPrivate *priv = META_DEFAULT_PLUGIN (plugin)->priv;

  return &priv->info;
}

static void
on_dialog_closed (GPid     pid,
                  gint     status,
                  gpointer user_data)
{
  MetaPlugin *plugin = user_data;
  gboolean ok;

  ok = g_spawn_check_exit_status (status, NULL);
  meta_plugin_complete_display_change (plugin, ok);
}

static void
confirm_display_change (MetaPlugin *plugin)
{
  GPid pid;

  pid = meta_show_dialog ("--question",
                          "Does the display look OK?",
                          "20",
                          NULL,
                          "_Keep This Configuration",
                          "_Restore Previous Configuration",
                          "preferences-desktop-display",
                          0,
                          NULL, NULL);

  g_child_watch_add (pid, on_dialog_closed, plugin);
}
