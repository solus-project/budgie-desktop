/*
 * BudgieSession.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

    const string WM_NAME = "budgie-wm";
    const string PANEL_NAME = "budgie-panel";
    /* Never attempt to relaunch something more than 3 times */
    const int MAX_LAUNCH = 3;

    /**
     * Simple container class to monitor processes, and how many times they
     * have been launched, etc.
     */
    protected class  WatchedProcess {

        /** Current PID of the process */
        public Pid pid { public get; public set; }

        /** Number of times this process has been launched */
        public int n_times { public get; public set; }

         /** Command line for the process */
        public string cmd_line { public get; public set; }
    }

/**
 * Budgie.Session is responsible for session management within the Budgie
 * Desktop
 */
public class Session : GLib.Application
{

    bool running = false;
    GLib.MainLoop loop = null;
    Gee.HashMap<string,WatchedProcess?> process_map;
    // xdg mapping
    Gee.HashMap<string,DesktopAppInfo>  mapping;
    bool relaunch = true;

    /**
     * We only ever want to be activated once (unique instance)
     */
    public override void activate()
    {
        if (running) {
            stdout.printf("Session already running\n");
            return;
        }

        hold();
        running = true;
        prepare_xdg();

        process_map = new Gee.HashMap<string,WatchedProcess?>(null,null,null);
        launch_xdg("Initialization");

        /* Launch our items - want the window manager first */
        if (!launch_watched(WM_NAME)) {
            critical("Unable to launch %s", WM_NAME);
            Process.exit(1);
        }
        launch_xdg("WindowManager");

        // Now we need all "init" style items
        if (!launch_watched(PANEL_NAME)) {
            critical("Unable to launch %s", PANEL_NAME);
        }
        // And now "panel" style items, where appropriate
        launch_xdg("Panel");

        // And now all you other fellers.
        launch_xdg("Desktop");
        launch_xdg("Applications");

        loop.run();

        release();
    }

    /**
     * Launch a process and keep it in a monitored state
     */
    protected bool launch_watched(string cmdline)
    {
        WatchedProcess? p;
        Pid pid;
        int fdin, fdout, fderr;
        string[] argv;
        string[] environ = Environ.get();
        string home_dir = Environment.get_home_dir();

        /* Split cmdline into argv */
        try {
            GLib.Shell.parse_argv(cmdline, out argv);
        } catch (GLib.ShellError e) {
            stderr.printf("Error parsing command line: %s\n", e.message);
            return false;
        }

        if (!process_map.has_key(cmdline)) {
            p = new WatchedProcess();
            p.n_times = 0;
        } else {
            p = process_map[cmdline];
        }

        try {
            Process.spawn_async_with_pipes(home_dir,
                argv, environ,
                SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
                null, out pid, out fdin, out fdout, out fderr);
        } catch (SpawnError e) {
            stderr.printf("Could not spawn command: %s\n", e.message);
            return false;
        }

        p.pid = pid;
        p.cmd_line = cmdline;
        // Increment the times we've launched this fella
        p.n_times += 1;
        process_map[cmdline] = p;
        /* Watch the child and see if it dies */
        ChildWatch.add(pid, child_reaper);

        return true;
    }

    /**
     * Handle processes that died
     */
    protected void child_reaper(Pid pid, int status)
    {
        WatchedProcess? p = null;

        foreach (var process in process_map.values) {
            if (process.pid == pid) {
                p = process;
                break;
            }
        }

        stdout.printf("%d (%s) closed with exit code: %d\n", pid, p.cmd_line, status);
        stdout.printf("Launched %d times\n", p.n_times);

        Process.close_pid(pid);
        /* Relaunch borked processes only */
        if (p.n_times < MAX_LAUNCH && status != 0 && relaunch) {
            Idle.add(()=> {
                launch_watched(p.cmd_line);
                return false;
            });
            return;
        } else {
            if (status != 0) {
                warning("Not relaunching %s as it has died 3 times already", p.cmd_line);
                /* Now, if WM is dead or PANEL is dead we need to go bail. In future, handle
                 * this more gracefully. Like, a failwhale. Or squirrel. >_> */
                if (p.cmd_line == WM_NAME || p.cmd_line == PANEL_NAME) {
                    critical("Critical desktop component %s exited with status code %d", p.cmd_line, status);
                    do_logout();
                    loop.quit();
                }
            } // otherwise it was a normal requested operation
            process_map.unset(p.cmd_line);
        }
    }

    /*
     * Perform clean up work to tear down the desktop
     */
    private void do_logout()
    {
        if (!running) {
            warning("Cannot logout as not actually running\n");
            return;
        }

        hold();
        // just in case sending SIGTERM results in some oddity in a watched
        // process
        relaunch = false;
        // Kill processes that we explicitly own
        foreach (var process in process_map.values) {
            if (process.n_times < MAX_LAUNCH) {
                Posix.kill(process.pid, ProcessSignal.TERM);
                Process.close_pid(process.pid);
            }
        }
        loop.quit();
        release();
    }

    /**
     * Iterate the xdg autostarts
     */
    private void prepare_xdg()
    {
        mapping = new Gee.HashMap<string,DesktopAppInfo>(null,null,null);

        /* Layered from left to right - user at the end can override all */
        var xdgdirs = Environment.get_system_config_dirs();
        xdgdirs += Environment.get_user_config_dir();

        foreach (var dir in xdgdirs) {
            var startdir = @"$dir/autostart";
            var file = File.new_for_path(startdir);
            var info = file.query_file_type(FileQueryInfoFlags.NONE, null);
            FileInfo? next_info;

            if (info != FileType.DIRECTORY) {
                continue;
            }

            try {
                var listing = file.enumerate_children("standard::*", FileQueryInfoFlags.NONE, null);

                /* Iterate children */
                while ((next_info = listing.next_file(null)) != null) {
                    try {
                        var path = next_info.get_name();
                        if (!path.has_suffix(".desktop")) {
                            continue;
                        }
                        var fullpath = @"$startdir/$path";
                        var nfile = File.new_for_path(fullpath);
                        var cinfo = nfile.query_info("standard::*", FileQueryInfoFlags.NONE, null);
                        if (cinfo.get_is_symlink()) {
                            /* If this is a link to /dev/null its disabled */
                            if (cinfo.get_symlink_target() == "/dev/null") {
                                // Remove from the previously built table
                                if (mapping.has_key(path)) {
                                    mapping.unset(path);
                                    continue;
                                }
                            }
                        }

                        var appinfo = new DesktopAppInfo.from_filename(fullpath);
                        if (appinfo == null) {
                            continue;
                        }
                        if (should_autostart(ref appinfo)) {
                            /* Quite simply, always override the same .desktop file names
                             * from the previous run for a layering effect */
                            mapping[path] = appinfo;
                        } else {
                            /* Overridden layer might have changed something */
                            if (mapping.has_key(path)) {
                                mapping.unset(path);
                            }
                        }
                    } catch (Error e) {
                        stderr.printf("Error: %s\n", e.message);
                    }
                }
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }
        }
    }

    /**
     * Launch session entries conforming to NewGnomeSession
     * https://wiki.gnome.org/Projects/SessionManagement/NewGnomeSession
     *
     * Note: "Applications" is also a catch-call for anything that is *not*
     * categorised
     */
    protected void launch_xdg(string condition)
    {
        foreach (var entry in mapping.values) {
            bool launch = false;
            bool monitor = false;
            int delay = 0;

            if (entry.has_key("X-GNOME-Autostart-Phase")) {
                var phase = entry.get_string("X-GNOME-Autostart-Phase");
                if (condition != phase) {
                    continue;
                }
                launch = true;
            } else if (condition == "Applications") {
                launch = true;
            }
            // determine if we need to monitor it
            if (entry.has_key("X-GNOME-AutoRestart")) {
                monitor = entry.get_boolean("X-GNOME-AutoRestart");
            }
            // does it need a delay?
            if (entry.has_key("X-GNOME-Autostart-Delay")) {
                string del = entry.get_string("X-GNOME-Autostart-Delay");
                delay = int.parse(del);
            }

            /* So, go launch it. */
            try {
                if (monitor) {
                    /* Monitored processes are handled by us */
                    if (delay > 0) {
                        Timeout.add(delay, ()=> {
                            launch_watched(entry.get_commandline());
                            return false;
                        });
                    } else {
                        launch_watched(entry.get_commandline());
                    }
                } else {
                    if (delay > 0) {
                        Timeout.add(delay, ()=> {
                            entry.launch(null, null);
                            return false;
                        });
                    } else {
                        entry.launch(null, null);
                    }
                }
            } catch (Error e) {
                warning("Unable to launch item: %s", e.message);
            }
        }
    }

    protected bool should_autostart(ref DesktopAppInfo info)
    {
        bool ret = false;
        /* First condition, check we should show */
        if (info.has_key("OnlyShowIn")) {
            var showin = info.get_string("OnlyShowIn");
            if ("Budgie;" in showin || "GNOME;" in showin) {
                ret = true;
            } else {
                ret = false;
            }
        }

        if (!ret) {
            return ret;
        }

        /* Secondly, determine if its a gsettings key step */
        if (info.has_key("AutostartCondition")) {
            var splits = info.get_string("AutostartCondition").split(" ", 3);
            if (splits[0] != "GSettings") {
                return false;
            }
            var settings = new Settings(splits[1]);
            return settings.get_boolean(splits[2]) == true;
        }
        return true;
    }

    private Session()
    {
        Object (application_id: "com.evolve_os.BudgieSession", flags: 0);
        loop = new MainLoop(null, false);

        var action = new SimpleAction("logout", null);
        action.activate.connect(()=> {
            do_logout();
        });
        add_action(action);
    }

    static bool should_logout = false;

	private const GLib.OptionEntry[] options = {
        { "logout", 0, 0, OptionArg.NONE, ref should_logout, "Logout", null },
        { null }
    };

    /**
     * Main entry   
     */
    public static int main(string[] args)
    {
        Budgie.Session app;

        try {
            var opt_context = new OptionContext("- Budgie Session");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(options, null);
            opt_context.parse(ref args);
        } catch (OptionError e) {
            stdout.printf("Error: %s\nRun with --help to see valid options\n", e.message);
            return 0;
        }

        app = new Budgie.Session();

        if (should_logout) {
            try {
                app.register(null);
                app.activate_action("logout", null);
                Process.exit(0);
            } catch (Error e) {
                stderr.printf("Error activating logout: %s\n", e.message);
                return 1;
            }
        }

        return app.run(args);
    }
} // End Session

} // End Budgie namespace
