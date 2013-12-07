/*
 * budgie-wm.c - Budgie Window Manager (mutter based)
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

#include <meta/main.h>

#define GAIL_OPT "NO_GAIL"
#define AT_BRIDGE_OPT "NO_AT_BRIDGE"

int main(int argc, char **argv)
{
        GOptionContext *ctx;

        /* Add default option context */
        ctx = meta_get_option_context();
        if (!g_option_context_parse(ctx, &argc, &argv, NULL))
                return FALSE;

        /* Respect the fact its still Mutter.. but don't be it */
        meta_set_wm_name("Mutter(Budgie)");

        /* Initialise, prevent certain things loading */
        g_setenv(GAIL_OPT, "1", TRUE);
        g_setenv(AT_BRIDGE_OPT, "1", TRUE);
        meta_init();

        /* Reset the options */
        g_unsetenv(GAIL_OPT);
        g_unsetenv(AT_BRIDGE_OPT);

        return meta_run();
}
