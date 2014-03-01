/*
 * plugin.h
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

#define META_TYPE_DEFAULT_PLUGIN            (meta_default_plugin_get_type ())
#define META_DEFAULT_PLUGIN(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), META_TYPE_DEFAULT_PLUGIN, MetaDefaultPlugin))
#define META_DEFAULT_PLUGIN_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass),  META_TYPE_DEFAULT_PLUGIN, MetaDefaultPluginClass))
#define META_IS_DEFAULT_PLUGIN(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), META_DEFAULT_PLUGIN_TYPE))
#define META_IS_DEFAULT_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass),  META_TYPE_DEFAULT_PLUGIN))
#define META_DEFAULT_PLUGIN_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj),  META_TYPE_DEFAULT_PLUGIN, MetaDefaultPluginClass))

#define META_DEFAULT_PLUGIN_GET_PRIVATE(obj) \
(G_TYPE_INSTANCE_GET_PRIVATE ((obj), META_TYPE_DEFAULT_PLUGIN, MetaDefaultPluginPrivate))

typedef struct _MetaDefaultPlugin        MetaDefaultPlugin;
typedef struct _MetaDefaultPluginClass   MetaDefaultPluginClass;
typedef struct _MetaDefaultPluginPrivate MetaDefaultPluginPrivate;

#define BACKGROUND_SCHEMA "org.gnome.desktop.background"
#define PICTURE_URI_KEY       "picture-uri"
#define BACKGROUND_STYLE_KEY "picture-options"
#define PRIMARY_COLOR_KEY "primary-color"
#define SECONDARY_COLOR_KEY "secondary-color"
#define COLOR_SHADING_TYPE_KEY "color-shading-type"

#define GNOME_COLOR_HACK "gnome-control-center/pixmaps/noise-texture-light.png"

#define BUDGIE_WM_SCHEMA "com.evolve-os.budgie.wm"
#define MUTTER_EDGE_TILING "edge-tiling"
#define MUTTER_MODAL_ATTACH "attach-modal-dialogs"

struct _MetaDefaultPlugin
{
  MetaPlugin parent;

  MetaDefaultPluginPrivate *priv;
};

struct _MetaDefaultPluginClass
{
  MetaPluginClass parent_class;
};

GType meta_default_plugin_get_type (void);
