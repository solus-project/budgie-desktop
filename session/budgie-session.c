/*
 * budgie-session.c
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

#include <stdlib.h>
#include <stdio.h>
#include <gio/gio.h>
#include <sys/wait.h>

#define DESKTOP_WM "mutter"
#define DESKTOP_PANEL "budgie-panel"
#define DESKTOP_EXTRA "gnome-terminal"
#define WD "/tmp"

int main(int argc, char **argv)
{
        GError *error = NULL;
        gint exit = 0;
        GPid pid;
        __attribute__ ((unused)) int c_ret;
        gchar **p_argv = NULL;
        int wID;
        int ret = EXIT_FAILURE;

        /* Need to pass an argv to g_spawn_async */
        if (!g_shell_parse_argv(DESKTOP_WM, NULL, &p_argv, &error)) {
                fprintf(stderr, "g_shell_parse_argv() failed\n");
                g_error_free(error);
                return EXIT_FAILURE;
        }

        /* Launch WM immediately async, so we can start other display
         * dependant child processes */
        if (!g_spawn_async(WD, p_argv, NULL,
                G_SPAWN_STDOUT_TO_DEV_NULL | G_SPAWN_STDERR_TO_DEV_NULL |
                G_SPAWN_DO_NOT_REAP_CHILD | G_SPAWN_SEARCH_PATH,
                NULL, NULL, &pid, &error)) {
                fprintf(stderr, "Unable to launch window manager: %s\n",
                        error->message);
                fprintf(stderr, "Child exited with code %d\n", exit);
                goto end;
        }

        /* Launch panel component */
        if (!g_spawn_command_line_async(DESKTOP_PANEL, &error)) {
                fprintf(stderr, "Unable to launch panel: %s\n",
                        error->message);
                goto end;
        }

        /* Launch extra (currently gnome terminal) */
        if (!g_spawn_command_line_async(DESKTOP_EXTRA, &error)) {
                fprintf(stderr, "Unable to launch extra component: %s\n",
                        error->message);
                goto end;
        }

        /* Now we wait for previously async-launched WM to exit */
        while (TRUE) {
                wID = waitpid(pid, &c_ret, WNOHANG|WUNTRACED);
                if (wID < 0) {
                        fprintf(stderr, "waitpid(%d) failure. Aborting\n",
                                wID);
                        goto child_end;
                } else if (wID == 0)
                        sleep(1);
                else if (wID == pid)
                        break;
        }
        ret = EXIT_SUCCESS;
child_end:
        g_spawn_close_pid(pid);
end:
        if (error)
                g_error_free(error);
        if (p_argv)
                g_strfreev(p_argv);
        
        return ret;
}
