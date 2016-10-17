/*
 * This file is part of budgie-desktop
 *
 * Copyright (C) 2016 Ikey Doherty <ikey@solus-project.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {


/**
 * IBusManager is responsible for interfacing with the ibus daemon
 * under Budgie Desktop, enabling extra input sources to be used
 * when using the ibus XIM daemon
 */
public class IBusManager : GLib.Object
{
    private IBus.Bus? bus = null;
    private bool ibus_available = true;

    /* Current engine name for ibus */
    private string ibus_engine_name;

    /**
     * Construct a new IBusManager which will begin setting up the
     * ibus daemon, as well as registering events to connect to it
     * and monitor it.
     */
    public IBusManager()
    {
        Object();

        /* No ibus-daemon = no ibus manager */
        if (Environment.find_program_in_path("ibus-daemon") == null) {
            this.ibus_available = false;
        }

        /* Get the bus */
        bus = new IBus.Bus.async();

        /* Hook up basic signals */
        bus.connected.connect(this.ibus_connected);
        bus.disconnected.connect(this.ibus_disconnected);
        bus.set_watch_dbus_signal(true);
        bus.global_engine_changed.connect(this.ibus_engine_changed);

        /* Start the ibus daemon */
        this.startup_ibus();
    }

    /**
     * Launch the daemon as a child process so that it dies when we die
     */
    private void startup_ibus()
    {
        string[] cmdline = {"ibus-daemon", "--xim", "--panel", "disable"};
        try {
            new Subprocess.newv(cmdline, SubprocessFlags.NONE);
        } catch (Error e) {
            GLib.message("Failed to launch ibus: %s", e.message);
            this.ibus_available = false;
        }
    }

    private void on_engines_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        GLib.List<weak IBus.EngineDesc>? engines = null;
        try {
            engines = this.bus.list_engines_async_finish(res);
        } catch (Error e) {
            GLib.message("Failed to get engines: %s", e.message);
            return;
        }
        GLib.message("Got engines");
    }

    /**
     * We gained connection to the ibus daemon
     */
    private void ibus_connected()
    {
        /* Do nothing for now */
        GLib.message("ibus connected");
        // this.bus.list_engines_async.begin(-1, null, on_engines_get);
    }

    /**
     * Lost connection to ibus
     */
    private void ibus_disconnected()
    {
        /* Also do nothing for now */
        GLib.message("ibus disconnected");
    }

    /**
     * The global ibus engine changed
     */
    private void ibus_engine_changed(string new_engine)
    {
        /* Do nothing but spam the engine name */
        this.ibus_engine_name = new_engine;
        GLib.message("new engine: %s", this.ibus_engine_name);
    }
}

} /* End namespace */
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
