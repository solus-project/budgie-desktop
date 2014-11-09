/* -*- mode: C; c-file-style: "gnu"; indent-tabs-mode: nil; -*- */

/*
 * Copyright (c) 2008 Intel Corp.
 *
 * Author: Tomas Frydrych <tf@linux.intel.com>
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

#pragma GCC diagnostic ignored "-Wdeprecated"
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
/* Because GCC is tripping about the bitfields */
#pragma GCC diagnostic ignored "-Woverflow"

#include <config.h>

#include <meta/meta-plugin.h>
#include <meta/window.h>
#include <meta/meta-background-group.h>
#include <meta/meta-background-actor.h>
#include <meta/prefs.h>
#include <meta/keybindings.h>
#include <meta/util.h>
#include <glib/gi18n-lib.h>
#include <meta/meta-version.h>

#include <clutter/clutter.h>
#include <gmodule.h>
#include <string.h>

#define DESTROY_TIMEOUT    100
#define DESTROY_SCALE      0.8
#define MINIMIZE_TIMEOUT   150
#define MAXIMIZE_TIMEOUT   100
#define MAP_TIMEOUT        110
#define MAP_SCALE          0.8
#define BACKGROUND_TIMEOUT 250
#define SWITCH_TIMEOUT    500

#include "plugin.h"

#define ACTOR_DATA_KEY "MCCP-Default-actor-data"
#define SCREEN_TILE_PREVIEW_DATA_KEY "MCCP-Default-screen-tile-preview-data"

static GQuark actor_data_quark = 0;
static GQuark screen_tile_preview_data_quark = 0;

static void start      (MetaPlugin      *plugin);
static void minimize   (MetaPlugin      *plugin,
                        MetaWindowActor *actor);
static void map        (MetaPlugin      *plugin,
                        MetaWindowActor *actor);
static void destroy    (MetaPlugin      *plugin,
                        MetaWindowActor *actor);

static void switch_workspace (MetaPlugin          *plugin,
                              gint                 from,
                              gint                 to,
                              MetaMotionDirection  direction);

static void kill_window_effects   (MetaPlugin      *plugin,
                                   MetaWindowActor *actor);
static void kill_switch_workspace (MetaPlugin      *plugin);

static void show_tile_preview (MetaPlugin      *plugin,
                               MetaWindow      *window,
                               MetaRectangle   *tile_rect,
                               int              tile_monitor_number);
static void hide_tile_preview (MetaPlugin      *plugin);

static void confirm_display_change (MetaPlugin *plugin);

static const MetaPluginInfo * plugin_info (MetaPlugin *plugin);

G_DEFINE_TYPE (MetaDefaultPlugin, meta_default_plugin, META_TYPE_PLUGIN)

static void
on_monitors_changed (MetaScreen *screen,
                     MetaPlugin *plugin);

static void settings_cb (GSettings *settings,
                          gchar *key,
                          gpointer userdata);

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

  GSettings            *settings;

  MetaPluginInfo         info;
};

/*
 * Per actor private data we attach to each actor.
 */
typedef struct _ActorPrivate
{
  ClutterActor *orig_parent;

  ClutterTimeline *tml_minimize;
  ClutterTimeline *tml_destroy;
  ClutterTimeline *tml_map;
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
                         ClutterKeyEvent *event,
                         MetaKeyBinding *binding,
                         gpointer        user_data)
{
  /* Ask budgie-panel to open the menu */
  g_spawn_command_line_async("budgie-panel --menu", NULL);
}

void budgie_launch_rundialog (MetaDisplay    *display,
                              MetaScreen     *screen,
                              MetaWindow     *window,
                              ClutterKeyEvent *event,
                              MetaKeyBinding *binding,
                              gpointer        user_data)
{
  /* Run the budgie-run-dialog
   * TODO: Make this path customisable */
  g_spawn_command_line_async("budgie-run-dialog", NULL);
}

typedef struct _ScreenTilePreview
{
  ClutterActor   *actor;

  GdkRGBA        *preview_color;

  MetaRectangle   tile_rect;
} ScreenTilePreview;

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
  plugin_class->destroy          = destroy;
  plugin_class->switch_workspace = switch_workspace;
  plugin_class->show_tile_preview = show_tile_preview;
  plugin_class->hide_tile_preview = hide_tile_preview;
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

static void
on_monitors_changed (MetaScreen *screen,
                     MetaPlugin *plugin)
{
  MetaDefaultPlugin *self = META_DEFAULT_PLUGIN (plugin);
  __attribute__ ((unused)) ClutterAnimation *animation;
  int i, n;
  GRand *rand = g_rand_new_with_seed (12345);
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
      MetaRectangle rect;
      ClutterActor *background_actor;
      MetaBackground *background;
      ClutterColor color;

      meta_screen_get_monitor_geometry (screen, i, &rect);

      background_actor = meta_background_actor_new (screen, i);

      clutter_actor_set_position (background_actor, rect.x, rect.y);
      clutter_actor_set_size (background_actor, rect.width, rect.height);

      background = meta_background_new (screen);
      if (random_colour)
      {
        /* Don't use rand() here, mesa calls srand() internally when
           parsing the driconf XML, but it's nice if the colors are
           reproducible.
        */
        clutter_color_init (&color,
                            g_rand_int_range (rand, 0, 255),
                            g_rand_int_range (rand, 0, 255),
                            g_rand_int_range (rand, 0, 255),
                            255);
        meta_background_set_color (background, &color);
      } else {
        if (style == G_DESKTOP_BACKGROUND_STYLE_NONE ||
            g_str_has_suffix (filename, GNOME_COLOR_HACK))
        {
          if (shading_direction == G_DESKTOP_BACKGROUND_SHADING_SOLID)
            meta_background_set_color (background, &primary_color);
          else
            meta_background_set_gradient (background,
                                           shading_direction,
                                           &primary_color,
                                           &secondary_color);
        } else {
          /* Set the background */
          #if META_MINOR_VERSION > 14
          if (wallpaper_file)
          {
            meta_background_set_file (background,
                                      wallpaper_file,
                                      style);
          }
          #else
          meta_background_set_filename (background,
                                        filename,
                                        style);
          #endif
        }
      }
      meta_background_actor_set_background (META_BACKGROUND_ACTOR (background_actor), background);
      g_object_unref (background);

      meta_screen_get_monitor_geometry (screen, i, &rect);

      clutter_actor_set_position (background_actor, rect.x, rect.y);
      clutter_actor_set_size (background_actor, rect.width, rect.height);
      clutter_actor_add_child (self->priv->background_group, background_actor);
      clutter_actor_set_scale (background_actor, 0.0, 0.0);
      clutter_actor_show (background_actor);
      clutter_actor_set_pivot_point (background_actor, 0.5, 0.5);

      /* Ease in the background using a scale effect */
      animation = clutter_actor_animate (background_actor, CLUTTER_EASE_IN_SINE,
                                         BACKGROUND_TIMEOUT,
                                         "scale-x", 1.0,
                                         "scale-y", 1.0,
                                         NULL);

    }

    if (wallpaper_file)
    {
      g_object_unref(wallpaper_file);
    }
    g_free(wallpaper);
    g_free(filename);
    g_rand_free (rand);
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

  clutter_actor_show (meta_get_stage_for_screen (screen));

  /* Set up our own keybinding overrides */
  meta_keybindings_set_custom_handler(BUDGIE_KEYBINDING_MAIN_MENU,
                                      budgie_launch_menu, NULL, NULL);
  meta_keybindings_set_custom_handler(BUDGIE_KEYBINDING_RUN_DIALOG,
                                      budgie_launch_rundialog, NULL, NULL);
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
      ActorPrivate    *apriv        = get_actor_private (window_actor);
      ClutterActor    *actor        = CLUTTER_ACTOR (window_actor);
      MetaWorkspace   *workspace;
      gint             win_workspace;

      workspace = meta_window_get_workspace (meta_window_actor_get_meta_window (window_actor));
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

  if (type == META_WINDOW_NORMAL || type == META_WINDOW_DIALOG || type == META_WINDOW_MODAL_DIALOG)
    {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);

      clutter_actor_set_pivot_point (actor, 0.5, 0.5);
      clutter_actor_set_opacity (actor, 0);
      clutter_actor_set_scale (actor, MAP_SCALE, MAP_SCALE);
      clutter_actor_show (actor);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_OUT_QUAD,
                                         MAP_TIMEOUT,
                                         "opacity", 255,
                                         "scale-x", 1.0,
                                         "scale-y", 1.0,
                                         "opacity", 255,
                                         NULL);
      apriv->tml_map = clutter_animation_get_timeline (animation);
      data->actor = actor;
      data->plugin = plugin;
      g_signal_connect (apriv->tml_map, "completed",
                        G_CALLBACK (on_map_effect_complete),
                        data);
    }
  else
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

  if (type == META_WINDOW_NORMAL || type == META_WINDOW_DIALOG || type == META_WINDOW_MODAL_DIALOG)
    {
      ClutterAnimation *animation;
      EffectCompleteData *data = g_new0 (EffectCompleteData, 1);
      ActorPrivate *apriv = get_actor_private (window_actor);

      animation = clutter_actor_animate (actor,
                                         CLUTTER_EASE_OUT_QUAD,
                                         DESTROY_TIMEOUT,
                                         "opacity", 0,
                                         "scale-x", DESTROY_SCALE,
                                         "scale-y", DESTROY_SCALE,
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

/*
 * Tile preview private data accessor
 */
static void
free_screen_tile_preview (gpointer data)
{
  ScreenTilePreview *preview = data;

  if (G_LIKELY (preview != NULL)) {
    clutter_actor_destroy (preview->actor);
    g_slice_free (ScreenTilePreview, preview);
  }
}

static ScreenTilePreview *
get_screen_tile_preview (MetaScreen *screen)
{
  ScreenTilePreview *preview = g_object_get_qdata (G_OBJECT (screen), screen_tile_preview_data_quark);

  if (G_UNLIKELY (screen_tile_preview_data_quark == 0))
    screen_tile_preview_data_quark = g_quark_from_static_string (SCREEN_TILE_PREVIEW_DATA_KEY);

  if (G_UNLIKELY (!preview))
    {
      preview = g_slice_new0 (ScreenTilePreview);

      preview->actor = clutter_actor_new ();
      clutter_actor_set_background_color (preview->actor, CLUTTER_COLOR_Blue);
      clutter_actor_set_opacity (preview->actor, 100);

      clutter_actor_add_child (meta_get_window_group_for_screen (screen), preview->actor);
      g_object_set_qdata_full (G_OBJECT (screen),
                               screen_tile_preview_data_quark, preview,
                               free_screen_tile_preview);
    }

  return preview;
}

static void
show_tile_preview (MetaPlugin    *plugin,
                   MetaWindow    *window,
                   MetaRectangle *tile_rect,
                   int            tile_monitor_number)
{
  MetaScreen *screen = meta_plugin_get_screen (plugin);
  ScreenTilePreview *preview = get_screen_tile_preview (screen);
  ClutterActor *window_actor;

  if (CLUTTER_ACTOR_IS_VISIBLE (preview->actor)
      && preview->tile_rect.x == tile_rect->x
      && preview->tile_rect.y == tile_rect->y
      && preview->tile_rect.width == tile_rect->width
      && preview->tile_rect.height == tile_rect->height)
    return; /* nothing to do */

  clutter_actor_set_position (preview->actor, tile_rect->x, tile_rect->y);
  clutter_actor_set_size (preview->actor, tile_rect->width, tile_rect->height);

  clutter_actor_show (preview->actor);

  window_actor = CLUTTER_ACTOR (meta_window_get_compositor_private (window));
  clutter_actor_lower (preview->actor, window_actor);

  preview->tile_rect = *tile_rect;
}

static void
hide_tile_preview (MetaPlugin *plugin)
{
  MetaScreen *screen = meta_plugin_get_screen (plugin);
  ScreenTilePreview *preview = get_screen_tile_preview (screen);

  clutter_actor_hide (preview->actor);
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
