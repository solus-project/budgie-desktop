/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2015-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

#include <gtk/gtk.h>

/* So gcc doesn't optimise the function out entirely */
static int dummy = 0;

void budgie_please_link_me_libtool_i_have_great_themes(void)
{
        int j = 1;
        dummy = j;
}

#define THEME_PREFIX "resource://com/solus-project/budgie/theme"

gchar *budgie_form_theme_path(const gchar *suffix)
{
        gint minor_version = gtk_get_minor_version();

        /* Prioritize 3.18 */
        switch (minor_version) {
        case 18:
                return g_strdup_printf("%s/3.18/%s", THEME_PREFIX, suffix);
        case 20:
        default:
                return g_strdup_printf("%s/3.20/%s", THEME_PREFIX, suffix);
        }
}
