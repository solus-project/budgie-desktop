/*
 * budgie-session.c
 * 
 * Copyright 2013 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <stdlib.h>
#include <stdio.h>
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>
#include <sys/wait.h>

#define BUDGIE_SESSION_ID "com.evolve_os.BudgieSession"
#define ACTION_LOGOUT "logout"

#define DESKTOP_WM "budgie-wm"

#define DESKTOP_PANEL "budgie-panel"
#define GSD_DESKTOP "/etc/xdg/autostart/gnome-settings-daemon.desktop"

static gboolean activated = FALSE;
static gboolean should_exit = FALSE;

static void activate(GApplication *application, gpointer userdata)
{
        if (activated) {
                return;
        }

        GError *error = NULL;
        gint exit = 0;
        GPid pid;
        __attribute__ ((unused)) int c_ret;
        gchar **p_argv = NULL;
        int wID;
        const gchar *home_dir;
        GDesktopAppInfo *gsd_app = NULL;
        const gchar *gsd_exec;

        home_dir = g_get_home_dir();

        gsd_app = g_desktop_app_info_new_from_filename(GSD_DESKTOP);
        if (gsd_app) {
                gsd_exec = g_app_info_get_executable(G_APP_INFO(gsd_app));
                /* Launch the settings daemon */
                if (!g_spawn_command_line_async(gsd_exec, &error)) {
                        fprintf(stderr, "Unable to launch settings: %s\n",
                                error->message);
                        goto end;
                }
        }

        /* Need to pass an argv to g_spawn_async */
        if (!g_shell_parse_argv(DESKTOP_WM, NULL, &p_argv, &error)) {
                fprintf(stderr, "g_shell_parse_argv() failed\n");
                g_error_free(error);
                return;
        }

        /* Launch WM immediately async, so we can start other display
         * dependant child processes */
        if (!g_spawn_async(home_dir, p_argv, NULL,
                G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL |
                G_SPAWN_DO_NOT_REAP_CHILD | G_SPAWN_SEARCH_PATH,
                NULL, NULL, &pid, &error)) {
                fprintf(stderr, "Unable to launch window manager: %s\n",
                        error->message);
                fprintf(stderr, "Child exited with code %d\n", exit);
                goto end;
        }

        /* Give the window manager a second to sort itself out */
        sleep(1);

        /* Launch panel component */
        if (!g_spawn_command_line_async(DESKTOP_PANEL, &error)) {
                fprintf(stderr, "Unable to launch panel: %s\n",
                        error->message);
                goto end;
        }

        activated = TRUE;
        g_application_hold(application);

        /* Now we wait for previously async-launched WM to exit */
        while (TRUE) {
                /* Logout requested */
                if (should_exit) {
                        goto child_end;
                }

                wID = waitpid(pid, &c_ret, WNOHANG|WUNTRACED);
                if (wID < 0) {
                        fprintf(stderr, "waitpid(%d) failure. Aborting\n",
                                wID);
                        goto child_end;
                } else if (wID == 0) {
                        g_main_context_iteration(NULL, TRUE);
                } else if (wID == pid) {
                        break;
                }
        }
child_end:
        g_spawn_close_pid(pid);
        g_application_release(application);
end:
        if (gsd_app) {
                g_object_unref(gsd_app);
        }
        if (error) {
                g_error_free(error);
        }
        if (p_argv) {
                g_strfreev(p_argv);
        }
}

static void logout_cb(GAction *action,
                      GVariant *param,
                      gpointer userdata)
{
        GApplication *application;

        application = G_APPLICATION(userdata);
        g_application_hold(application);
        /* Mark process for exit */
        should_exit = TRUE;
        g_application_release(application);
}

gint main(gint argc, gchar **argv)
{
        GApplication *app = NULL;
        GSimpleAction *action = NULL;
        int status = 0;

        app = g_application_new(BUDGIE_SESSION_ID, G_APPLICATION_FLAGS_NONE);
        g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);

        /* Logout action */
        action = g_simple_action_new(ACTION_LOGOUT, NULL);
        g_signal_connect(action, "activate", G_CALLBACK(logout_cb), app);
        g_action_map_add_action(G_ACTION_MAP(app), G_ACTION(action));
        g_object_unref(action);

        /* TODO: Use opts!! */
        if (argc > 1) {
                if (g_str_equal(argv[1], "--logout")) {
                        g_application_register(app, NULL, NULL);
                        g_action_group_activate_action(G_ACTION_GROUP(app),
                                ACTION_LOGOUT, NULL);
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
