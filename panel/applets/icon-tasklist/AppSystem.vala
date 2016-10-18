/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2014-2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class AppSystem : GLib.Object
{

    HashTable<string?,string?> startupids = null;
    HashTable<string?,string?> simpletons = null;
    HashTable<string?,DesktopAppInfo?> desktops = null;
    /* Mapping of based TryExec to desktop ID */
    HashTable<string?,string?> exec_cache = null;
    AppInfoMonitor? monitor = null;

    string[]? derpers;

    bool invalidated = false;

    public AppSystem()
    {
        /* Initialize simpletons. */
        simpletons = new HashTable<string?,string?>(str_hash, str_equal);
        simpletons["google-chrome-stable"] = "google-chrome";
        simpletons["calibre-gui"] = "calibre";
        simpletons["code - oss"] = "vscode-oss";
        simpletons["code"] = "vscode";
        simpletons["psppire"] = "pspp";

        derpers = new string[] {
            "atom",
            "calibre-gui",
            "dia",
            "freeorion",
            "fbreader",
            "google-chrome",
            "hexchat",
            "pale moon",
            "spotify",
            "steam",
            "telegram",
            "zim",
        };

        monitor = AppInfoMonitor.get();
        monitor.changed.connect(()=> {
            Idle.add(()=> {
                lock(invalidated) {
                    invalidated = true;
                }
                return Source.REMOVE;
            });
        });
        reload_ids();
    }

    /**
     * Determine if the app is forbidden from changing its icon through
     * the icon-changed signal
     */
    public bool has_derpy_icon(Wnck.Window? window)
    {
        string? iname = window.get_class_instance_name();
        if (iname == null) {
            return false;
        }
        iname = iname.down();
        if (iname in this.derpers) {
            return true;
        }
        return false;
    }

    /**
     * We lazily check if at some point we became invalidated. In most cases
     * a package operation or similar modified a desktop file, i.e. making it
     * available or unavailable.
     *
     * Instead of immediately reloading the appsystem we wait until something
     * is actually requested again, check if we're invalidated, reload and then
     * set us validated again.
     */
    private void check_invalidated()
    {
        if (invalidated) {
            lock (invalidated) {
                reload_ids();
                invalidated = false;
            }
        }
    }

    /**
     * Reload and cache all the desktop IDS
     */
    private void reload_ids()
    {
        startupids = new HashTable<string?,string?>(str_hash, str_equal);
        desktops = new HashTable<string?,DesktopAppInfo?>(str_hash, str_equal);
        exec_cache = new HashTable<string?,string?>(str_hash, str_equal);
        foreach (var appinfo in AppInfo.get_all()) {
            var dinfo = appinfo as DesktopAppInfo;
            if (dinfo.get_startup_wm_class() != null) {
                startupids[dinfo.get_startup_wm_class().down()] = dinfo.get_id();
            }
            desktops.insert(dinfo.get_id().down(), dinfo);

            /* Get TryExec if we can, otherwise main "executable" */
            string? try_exec = dinfo.get_string("TryExec");
            if (try_exec == null) {
                try_exec = dinfo.get_executable();
            }
            if (try_exec == null) {
                continue;
            }
            /* Sanitize it */
            try_exec = Uri.unescape_string(try_exec);
            try_exec = Path.get_basename(try_exec);

            exec_cache.insert(try_exec, dinfo.get_id());
        }
    }

    /**
     * Attempt to gain the DesktopAppInfo relating to a given window
     */
    public DesktopAppInfo? query_window(Wnck.Window? window)
    {
        ulong xid = window.get_xid();
        if (window == null) {
            return null;
        }
        string? cls_name = window.get_class_instance_name();
        string? grp_name = window.get_class_group_name();

        check_invalidated();

        string[] checks = new string[] { cls_name, grp_name };
        foreach (string? check in checks) {
            if (check == null) {
                continue;
            }
            /* First, check if we have something in the startupids for this app */
            check = check.down();
            if (check in startupids) {
                string dname = startupids[check].down();
                if (dname in desktops) {
                    return this.desktops[dname];
                }
            }
            /* Wasn't a startupid match, try class -> desktop match */
            string dname = check + ".desktop";
            if (dname in this.desktops) {
                return this.desktops[dname];
            }
        }

        /* Next, attempt to get the application based on the GtkApplication ID */
        string? gtk_id = this.query_gtk_application_id(xid);
        if (gtk_id != null) {
            gtk_id = gtk_id.down() + ".desktop";
            if (gtk_id in this.desktops) {
                return this.desktops[gtk_id];
            }
        }

        /* Is the group name in the simpletons? */
        if (grp_name != null && grp_name.down() in this.simpletons) {
            string dname = this.simpletons[grp_name.down()] + ".desktop";
            if (dname in this.desktops) {
                return this.desktops[dname];
            }
        } else if (cls_name != null && cls_name.down() in this.simpletons) {
            string dname = this.simpletons[cls_name.down()] + ".desktop";
            if (dname in this.desktops) {
                return this.desktops[dname];
            }
        }

        /* Last shot in the dark, try to match an exec line */
        foreach (string? check in checks) {
            if (check == null) {
                continue;
            }
            check = check.down();
            string? id = exec_cache.lookup(check);
            if (id == null) {
                continue;
            }
            unowned DesktopAppInfo? a = this.desktops.lookup(id);
            if (a != null) {
                return a;
            }
        }

        /* IDK. Sorry. */
        return null;
    }

    /**
     * Return a plain STRING value for the given window id
     */
    public string? query_atom_string(ulong xid, Gdk.Atom atom) {
        return this.query_atom_string_internal(xid, atom, false);
    }

    /**
     * Return a UTF8_STRING value for the given window id
     */
    public string? query_atom_string_utf8(ulong xid, Gdk.Atom atom) {
        return this.query_atom_string_internal(xid, atom, true);
    }

    private string? query_atom_string_internal(ulong xid, Gdk.Atom atom, bool utf8)
    {
        uint8[]? data = null;
        Gdk.Atom a_type;
        int a_f;
        var display = Gdk.Display.get_default();

        Gdk.Atom req_type;
        if (utf8) {
            req_type = Gdk.Atom.intern("UTF8_STRING", false);
        } else {
            req_type = Gdk.Atom.intern("STRING", false);
        }

        /**
         * Attempt to gain foreign window connection
         */
        Gdk.Window? foreign = Gdk.X11Window.foreign_new_for_display(display, xid);
        if (foreign == null) {
            /* No window, bail */
            return null;
        }
        /* Grab the property in question */
        Gdk.property_get(foreign, atom, req_type, 0, (ulong)long.MAX, 0,
                         out a_type, out a_f, out data);
        return data != null ? (string)data : null;
    }

    /**
     * Obtain the GtkApplication id for a given window
     */
    public string? query_gtk_application_id(ulong window)
    {
        return this.query_atom_string_utf8(window, Gdk.Atom.intern("_GTK_APPLICATION_ID", false));
    }
}

/*
 * Editor modelines  -  https://www.wireshark.org/tools/modelines.html
 *
 * Local variables:
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 *
 * vi: set shiftwidth=4 tabstop=4 expandtab:
 * :indentSize=4:tabSize=4:noTabs=true:
 */

