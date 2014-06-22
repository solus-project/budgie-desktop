/*
 * budgie-panel.h
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include "budgie-panel.h"
#include <stdlib.h>

gint main(gint argc, gchar **argv)
{
        __attribute__ ((unused)) BudgiePanel *panel;

        gtk_init(&argc, &argv);
        panel = budgie_panel_new();
        gtk_main();

        return EXIT_SUCCESS;
}
