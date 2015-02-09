/*
 * background.c
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * Copyright 2014 Emanuel Fernandes <efernandes@tektorque.com> (color/modes handling)
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <meta/meta-background-actor.h>
#include <meta/meta-background.h>
#include <meta/meta-background-group.h>
#include <meta/meta-version.h>

#include "background.h"

#define BACKGROUND_SCHEMA "org.gnome.desktop.background"
#define PICTURE_URI_KEY   "picture-uri"
#define PRIMARY_COLOR_KEY "primary-color"
#define SECONDARY_COLOR_KEY "secondary-color"
#define COLOR_SHADING_TYPE_KEY "color-shading-type"
#define BACKGROUND_STYLE_KEY "picture-options"
#define GNOME_COLOR_HACK "gnome-control-center/pixmaps/noise-texture-light.png"

#define BACKGROUND_TIMEOUT 850

struct _BudgieBackgroundPrivate
{
        MetaScreen *screen;
        GSettings *settings;
        ClutterActor *bg;
        ClutterActor *old_bg;
        int index;
};
static void _update(BudgieBackground *self);

G_DEFINE_TYPE_WITH_PRIVATE(BudgieBackground, budgie_background, META_TYPE_BACKGROUND_GROUP)

/* Boilerplate GObject code */
static void budgie_background_class_init(BudgieBackgroundClass *klass);
static void budgie_background_init(BudgieBackground *self);
static void budgie_background_dispose(GObject *object);
static GObject *budgie_background_construct(GType type, guint n_props, GObjectConstructParam *props);

enum {
        PROP_0, PROP_SCREEN, PROP_INDEX, N_PROPERTIES
};

static GParamSpec *obj_properties[N_PROPERTIES] = { NULL,};

static void budgie_background_set_property(GObject *object,
                                           guint prop_id,
                                           const GValue *value,
                                           GParamSpec *pspec)
{
        BudgieBackground *self;

        self = BUDGIE_BACKGROUND(object);
        switch (prop_id) {
                case PROP_SCREEN:
                        self->priv->screen = g_value_get_pointer((GValue*)value);
                        break;
                case PROP_INDEX:
                        self->priv->index = g_value_get_int((GValue*)value);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
                                prop_id, pspec);
                        break;
        }
}

static void budgie_background_get_property(GObject *object,
                                           guint prop_id,
                                           GValue *value,
                                           GParamSpec *pspec)
{
        BudgieBackground *self;

        self = BUDGIE_BACKGROUND(object);
        switch (prop_id) {
                case PROP_SCREEN:
                        g_value_set_pointer((GValue *)value, self->priv->screen);
                        break;
                case PROP_INDEX:
                        g_value_set_int((GValue*)value, self->priv->index);
                        break;
                default:
                        G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
                                prop_id, pspec);
                        break;
        }
}

/* Initialisation */
static void budgie_background_class_init(BudgieBackgroundClass *klass)
{
        GObjectClass *g_object_class;
        obj_properties[PROP_SCREEN] =
        g_param_spec_pointer("screen", "Screen", "Screen",
                G_PARAM_CONSTRUCT | G_PARAM_WRITABLE);
        obj_properties[PROP_INDEX] =
        g_param_spec_int("index", "Index", "Index",
                0, 100, 0, G_PARAM_CONSTRUCT | G_PARAM_WRITABLE);

        g_object_class = G_OBJECT_CLASS(klass);
        g_object_class->dispose = &budgie_background_dispose;
        g_object_class->set_property = &budgie_background_set_property;
        g_object_class->get_property = &budgie_background_get_property;
        g_object_class->constructor = &budgie_background_construct;
        g_object_class_install_properties(g_object_class, N_PROPERTIES,
                obj_properties);
}

static void on_key_change(GSettings *settings, const gchar *key, BudgieBackground *self)
{
        _update(self);
}

static GObject* budgie_background_construct(GType type, guint n_props, GObjectConstructParam *props)
{
        GObject *o = NULL;
        BudgieBackground *self;
        MetaRectangle rect;

        o = G_OBJECT_CLASS(budgie_background_parent_class)->constructor(type, n_props, props);

        self = BUDGIE_BACKGROUND(o);

        /* Size ourself to our parent screen/monitor */
        meta_screen_get_monitor_geometry(self->priv->screen, self->priv->index, &rect);
        clutter_actor_set_position(CLUTTER_ACTOR(self), rect.x, rect.y);
        clutter_actor_set_size(CLUTTER_ACTOR(self), rect.width, rect.height);

        g_signal_connect(self->priv->settings, "changed", G_CALLBACK(on_key_change), self);
        _update(self);

        return o;
}

static void budgie_background_init(BudgieBackground *self)
{
        /* Initial boilerplate cruft. */
        self->priv = budgie_background_get_instance_private(self);
        self->priv->settings = g_settings_new(BACKGROUND_SCHEMA);

        clutter_actor_set_background_color(CLUTTER_ACTOR(self),
                clutter_color_get_static(CLUTTER_COLOR_BLACK));
}

static void remove_old(ClutterActor *actor, BudgieBackground *self)
{
        /* When transition is complete just kill the actor */
        clutter_actor_destroy(actor);
        self->priv->old_bg = NULL;
}

static void begin_remove_old(ClutterActor *actor, BudgieBackground *self)
{
        /* Animate old fella out. */
        if (self->priv->old_bg && self->priv->old_bg != self->priv->bg) {
                g_signal_connect(self->priv->old_bg, "transitions-completed", G_CALLBACK(remove_old), self);
                clutter_actor_save_easing_state(self->priv->old_bg);
                clutter_actor_set_easing_mode(self->priv->old_bg, CLUTTER_EASE_OUT_QUAD);
                clutter_actor_set_easing_duration(self->priv->old_bg, BACKGROUND_TIMEOUT);
                g_object_set(self->priv->old_bg, "opacity", 0, NULL);
                clutter_actor_restore_easing_state(self->priv->old_bg);
        }
}

static void on_update(MetaBackground *background, BudgieBackground *self)
{
        /* Animate new fella in */
        clutter_actor_save_easing_state(self->priv->bg);
        g_signal_connect(self->priv->bg, "transitions-completed", G_CALLBACK(begin_remove_old), self);
        clutter_actor_set_easing_mode(self->priv->bg, CLUTTER_EASE_IN_EXPO);
        clutter_actor_set_easing_duration(self->priv->bg, BACKGROUND_TIMEOUT);
        g_object_set(self->priv->bg, "opacity", 255, NULL);
        clutter_actor_restore_easing_state(self->priv->bg);
}
/**
 * Actually update our appearance..
 * ATM this is totally hacky and only uses picture-uri :P
 */
static void _update(BudgieBackground *self)
{
        ClutterActor *actor = NULL;
        MetaBackground *background = NULL;
        MetaRectangle rect;
        GFile *bg_file = NULL;
        GDesktopBackgroundStyle style;
        GDesktopBackgroundShading  shading_direction;
        ClutterColor primary_color;
        ClutterColor secondary_color;
        gchar *color_str = NULL;

        gchar *bg_filename = g_settings_get_string(self->priv->settings,
                PICTURE_URI_KEY);

        style = g_settings_get_enum(self->priv->settings, BACKGROUND_STYLE_KEY);

        /* Creation of replacement actor */
        actor = meta_background_actor_new(self->priv->screen, self->priv->index);
        background = meta_background_new(self->priv->screen);
        meta_background_actor_set_background(META_BACKGROUND_ACTOR(actor), background);

        meta_screen_get_monitor_geometry(self->priv->screen, self->priv->index, &rect);
        clutter_actor_set_size(actor, rect.width, rect.height);
        g_object_set(actor, "opacity", 0, NULL);
        clutter_actor_show(actor);

        clutter_actor_insert_child_at_index(CLUTTER_ACTOR(self), actor, -1);
        if (self->priv->bg) {
                self->priv->old_bg = self->priv->bg;
        }
        self->priv->bg = actor;
        g_object_unref(background);

        g_signal_connect(background, "changed", G_CALLBACK(on_update), self);

        shading_direction = g_settings_get_enum(self->priv->settings, COLOR_SHADING_TYPE_KEY);
        /* Primary color */
        color_str = g_settings_get_string(self->priv->settings, PRIMARY_COLOR_KEY);
        if (color_str) {
                clutter_color_from_string(&primary_color, color_str);
                g_free(color_str);
                color_str = NULL;
        }

        /* Secondary color */
        color_str = g_settings_get_string(self->priv->settings, SECONDARY_COLOR_KEY);
        if (color_str) {
                clutter_color_from_string(&secondary_color, color_str);
                g_free(color_str);
                color_str = NULL;
        }

        if (style == G_DESKTOP_BACKGROUND_STYLE_NONE || g_str_has_suffix(bg_filename, GNOME_COLOR_HACK)) {
                if (shading_direction == G_DESKTOP_BACKGROUND_SHADING_SOLID) {
                        meta_background_set_color(background, &primary_color);
                } else {
                        meta_background_set_gradient(background, shading_direction,
                                &primary_color, &secondary_color);
                }
        } else {
                /* Load up the new wallpaper */

                bg_file = g_file_new_for_uri(bg_filename);

#if META_MINOR_VERSION > 14
                meta_background_set_file(background, bg_file, style);
#else
                char *filename = g_file_get_path(bg_file);
                if (filename) {
                        meta_background_set_filename(background, filename, style);
                        g_free(filename);
                } else {
                        g_message("Note: File does not exist...");
                }
#endif
                g_object_unref(bg_file);
        }
        g_free(bg_filename);
}

static void budgie_background_dispose(GObject *object)
{
        BudgieBackground *self = BUDGIE_BACKGROUND(object);
        if (self->priv->settings) {
                g_object_unref(self->priv->settings);
                self->priv->settings = NULL;
        }

        G_OBJECT_CLASS (budgie_background_parent_class)->dispose (object);
}

/* Utility; return a new BudgieBackground */
ClutterActor *budgie_background_new(MetaScreen *screen, int index)
{
        BudgieBackground *self;

        self = g_object_new(BUDGIE_BACKGROUND_TYPE, "screen", screen, "index", index, NULL);
        return CLUTTER_ACTOR(self);
}
