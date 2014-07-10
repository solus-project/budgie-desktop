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

#define BUDGIE_PANEL_ID "com.evolve_os.BudgiePanel"
#define ACTION_MENU "open-menu"

static gboolean activated = FALSE;

/* Currently only support a single BudgiePanel */
static BudgiePanel *panel;

/**
 * Main launch of BudgiePanel
 */
static void activate(GApplication *application, gpointer userdata)
{
        if (activated) {
                return;
        }

        panel = budgie_panel_new();
        activated = TRUE;
        gtk_main();
}

static void menu_cb(GAction *action,
                    GVariant *param,
                    gpointer userdata)
{
        /* Go and show the menu */
        budgie_panel_show_menu(panel);
}

gint main(gint argc, gchar **argv)
{
        GApplication *app = NULL;
        GSimpleAction *action = NULL;
        int status = 0;

        gtk_init(&argc, &argv);

        app = g_application_new(BUDGIE_PANEL_ID, G_APPLICATION_FLAGS_NONE);
        g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);

        /* Logout action */
        action = g_simple_action_new(ACTION_MENU, NULL);
        g_signal_connect(action, "activate", G_CALLBACK(menu_cb), app);
        g_action_map_add_action(G_ACTION_MAP(app), G_ACTION(action));
        g_object_unref(action);

        /* TODO: Also use opts.. */
        if (argc > 1) {
                if (g_str_equal(argv[1], "--menu")) {
                        g_application_register(app, NULL, NULL);
                        g_action_group_activate_action(G_ACTION_GROUP(app),
                                ACTION_MENU, NULL);
                } else {
                        printf("Unknown command: %s\n", argv[1]);
                        return EXIT_FAILURE;
                }
        } else {
                status = g_application_run(app, argc, argv);
        }

        g_object_unref(app);
        return status;
}
