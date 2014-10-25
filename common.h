/*
 * common.h - Common helpers for budgie-desktop
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

#pragma once

#include <glib.h>
#include <glib-object.h>

static inline void cleanup_free(void *p)
{
        void *v = *(void**)p;
        g_free(v);
}

static inline void cleanup_unref(void *p)
{
        void *v = *(void**)p;
        g_object_unref(G_OBJECT(v));
}

#define autofree __attribute__ ((cleanup(cleanup_free)))
#define autounref __attribute__ ((cleanup(cleanup_unref)))

static inline gboolean string_contains(const gchar *string, const gchar *term)
{
        autofree gchar *small1 = NULL;
        autofree gchar *small2 = NULL;
        gboolean ret = FALSE;
        gchar *found = NULL;

        if (!string || !term) {
                return FALSE;
        }

        small1 = g_ascii_strdown(term, -1);
        small2 = g_ascii_strdown(string, -1);
        found = g_strrstr(small2, small1);
        if (found) {
                ret = TRUE;
        }
        return ret;
}
