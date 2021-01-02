/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include <glib.h>

/**
 * Generate a dynamic resource path for the given suffix for a resource
 * contained within the libbudgie-theme.
 *
 * This performs a runtime check to determine the currently used version
 * of GTK+ to ensure that the appropriate theme-set is used. Currently
 * we support 3.22
 *
 * @return a Newly allocated string
 */
gchar* budgie_form_theme_path(const gchar* suffix);
