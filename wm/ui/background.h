/*
 * background.h
 * 
 * Copyright 2015 Ikey Doherty <ikey@evolve-os.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 */
#pragma once

#include <glib-object.h>
#include <clutter/clutter.h>
#include <meta/screen.h>

typedef struct _BudgieBackground BudgieBackground;
typedef struct _BudgieBackgroundClass   BudgieBackgroundClass;
typedef struct _BudgieBackgroundPrivate BudgieBackgroundPrivate;

#define BUDGIE_BACKGROUND_TYPE (budgie_background_get_type())
#define BUDGIE_BACKGROUND(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), BUDGIE_BACKGROUND_TYPE, BudgieBackground))
#define IS_BUDGIE_BACKGROUND(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), BUDGIE_BACKGROUND_TYPE))
#define BUDGIE_BACKGROUND_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), BUDGIE_BACKGROUND_TYPE, BudgieBackgroundClass))
#define IS_BUDGIE_BACKGROUND_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), BUDGIE_BACKGROUND_TYPE))
#define BUDGIE_BACKGROUND_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), BUDGIE_BACKGROUND_TYPE, BudgieBackgroundClass))

/* BudgieBackground object */
struct _BudgieBackground {
        MetaBackgroundGroup parent;
        /* TODO: Make private. */
        BudgieBackgroundPrivate* priv;
};

/* BudgieBackground class definition */
struct _BudgieBackgroundClass {
        ClutterActorClass parent_class;
};

GType budgie_background_get_type(void);

/* BudgieBackground methods */

/**
 * Construct a new BudgieBackground
 * @param screen Screen that this background will be on
 * @return A new BudgieBackground
 */
ClutterActor *budgie_background_new(MetaScreen *screen, int monitor);
