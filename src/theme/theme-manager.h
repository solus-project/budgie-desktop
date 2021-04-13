/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2016-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#pragma once

#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _BudgieThemeManager BudgieThemeManager;
typedef struct _BudgieThemeManagerClass BudgieThemeManagerClass;

#define BUDGIE_TYPE_THEME_MANAGER budgie_theme_manager_get_type()
#define BUDGIE_THEME_MANAGER(o) (G_TYPE_CHECK_INSTANCE_CAST((o), BUDGIE_TYPE_THEME_MANAGER, BudgieThemeManager))
#define BUDGIE_IS_THEME_MANAGER(o) (G_TYPE_CHECK_INSTANCE_TYPE((o), BUDGIE_TYPE_THEME_MANAGER))
#define BUDGIE_THEME_MANAGER_CLASS(o) (G_TYPE_CHECK_CLASS_CAST((o), BUDGIE_TYPE_THEME_MANAGER, BudgieThemeManagerClass))
#define BUDGIE_IS_THEME_MANAGER_CLASS(o) (G_TYPE_CHECK_CLASS_TYPE((o), BUDGIE_TYPE_THEME_MANAGER))
#define BUDGIE_THEME_MANAGER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS((o), BUDGIE_TYPE_THEME_MANAGER, BudgieThemeManagerClass))

BudgieThemeManager* budgie_theme_manager_new(void);

GType budgie_theme_manager_get_type(void);

G_END_DECLS
