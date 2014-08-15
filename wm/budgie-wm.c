/*
 * budgie-wm.c - Budgie Window Manager (mutter based)
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <meta/main.h>
#include <meta/meta-plugin.h>

#include "plugin.h"

#define GAIL_OPT "NO_GAIL"
#define AT_BRIDGE_OPT "NO_AT_BRIDGE"

int main(int argc, char **argv)
{
        GOptionContext *ctx;

        /* Add default option context */
        ctx = meta_get_option_context();
        if (!g_option_context_parse(ctx, &argc, &argv, NULL)) {
                return FALSE;
        }

        meta_plugin_manager_set_plugin_type(meta_default_plugin_get_type());

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
