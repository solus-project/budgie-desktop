/*
 * This file is part of budgie-desktop
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include <gtk/gtk.h>

#define THEME_PREFIX "resource://com/solus-project/budgie/theme"

gchar* budgie_form_theme_path(const gchar* suffix) {
	guint minor_version = gtk_get_minor_version();

	switch (minor_version) {
		case 20:
		default:
			return g_strdup_printf("%s/%s_3.20.css", THEME_PREFIX, suffix);
	}
}
