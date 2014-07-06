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
#include "common.h"

#define BUDGIE_SESSION_ID "com.evolve_os.BudgieSession"
#define ACTION_LOGOUT "logout"

#define DESKTOP_WM "budgie-wm"

#define DESKTOP_PANEL "budgie-panel"

static gboolean activated = FALSE;
static gboolean should_exit = FALSE;

/**
 * Activate all autostart entries
 * Note this is only done via SYSTEM directories, we currently DO NOT
 * support user-specific (~/.config/autostart) entries yet, as we'd
 * have to track what's been launched, and what to ignore, order of
 * execution, etc.
 */
static void activate_autostarts(void);

/**
 * Whether or not we should attempt to execute this entry.
 */
static gboolean should_autostart(GDesktopAppInfo *info);

/**
* Iterate a null terminated array
*/
#define foreach_string(x,y,i) const char *y = NULL;int i;\
for (i=0; (y = *(x+i)) != NULL; i++ )

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

        home_dir = g_get_home_dir();

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

        /* Ensures things like gnome-settings-daemon launch *after* the
         * window manager but before the panel */
        activate_autostarts();

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

static void activate_autostarts(void)
{
        const gchar * const *xdg_system = NULL;
        char *path = NULL;

        GFileType type;
        GFile *file = NULL;
        GFileInfo *next_file = NULL;
        GFileEnumerator *listing = NULL;
        const gchar *next_path;
        gchar *full_path;

        GDesktopAppInfo *app_info = NULL;

        xdg_system = g_get_system_config_dirs();
        if (!xdg_system) {
                g_warning("Unable to determine xdg system directories. Not autostarting applications\n");
                return;
        }

        /* Iterate each entry and launch all items in these directories */
        foreach_string(xdg_system, dir, i) {
                path = g_strdup_printf("%s/autostart", dir);
                if (!path) {
                        /* OOM */
                        abort();
                }

                /* Check we have a directory */
                file = g_file_new_for_path(path);
                type = g_file_query_file_type(file, G_FILE_QUERY_INFO_NONE, NULL);
                if (type != G_FILE_TYPE_DIRECTORY) {
                        goto next;
                }

                /* Enumerate this directory */
                listing = g_file_enumerate_children(file, "standard::*", G_FILE_QUERY_INFO_NONE,
                        NULL, NULL);

                while ((next_file = g_file_enumerator_next_file(listing, NULL, NULL)) != NULL) {
                        next_path = g_file_info_get_name(next_file);

                        /* Only interested in .desktop files */
                        if (!g_str_has_suffix(next_path, ".desktop")) {
                                continue;
                        }
                        full_path = g_strdup_printf("%s/%s", path, next_path);

                        /* Try to load it as a valid desktop file */
                        app_info = g_desktop_app_info_new_from_filename((const char*)full_path);
                        if (!app_info) {
                                goto failed;
                        }

                        /* Now launch it */
                        /* Eventually we're going to need a global launch context
                         * within Budgie. */
                        if (should_autostart(app_info)) {
                                if (!g_app_info_launch(G_APP_INFO(app_info), NULL, NULL, NULL)) {
                                        g_warning("Failed to launch: %s\n", full_path);
                                }
                        }

                        g_object_unref(app_info);
failed:
                        g_free(full_path);
                        g_object_unref(next_file);
                }
                g_file_enumerator_close(listing, NULL, NULL);
next:
                g_object_unref(file);
                g_free(path);
        }
}

static gboolean should_autostart(GDesktopAppInfo *info)
{
        g_assert(info != NULL);

        gboolean should_start = FALSE;
        gchar *show_in;

        if (g_desktop_app_info_has_key(info, "OnlyShowIn")) {
                show_in = g_desktop_app_info_get_string(info, "OnlyShowIn");
                /* Determine if its a GNOME or Budgie system */
                if (string_contains((const gchar*)show_in, "GNOME;") ||
                        string_contains((const gchar*)show_in, "Budgie;")) {
                        should_start = TRUE;
                }
                g_free(show_in);
        } else {
                /* Normal autostart - woo */
                should_start = TRUE;
        }

        if (should_start) {
                goto end;
        }

        /* TODO: Support Autostart "conditions" */

end:
        return should_start;
}

gint main(gint argc, gchar **argv)
{
        GApplication *app = NULL;
        GSimpleAction *action = NULL;
        int status = 0;

        g_setenv("DESKTOP_SESSION", "gnome", TRUE);

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
