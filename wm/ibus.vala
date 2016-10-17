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

    private HashTable<string,weak IBus.EngineDesc> engines = null;

    public unowned Budgie.KeyboardManager? kbm { construct set ; public get; }

    /* Current engine name for ibus */
    private string ibus_engine_name;

    private bool did_ibus_init = false;

    /**
     * Ensure that owning process knows we're up and running
     */
    public signal void ready();

    /**
     * Construct a new IBusManager which will begin setting up the
     * ibus daemon, as well as registering events to connect to it
     * and monitor it.
     */
    public IBusManager(Budgie.KeyboardManager? kbm)
    {
        Object(kbm: kbm);
    }

    public void do_init()
    {
        /* No ibus-daemon = no ibus manager */
        if (Environment.find_program_in_path("ibus-daemon") == null) {
            GLib.message("ibus-daemon unsupported on this system");
            this.ibus_available = false;
            this.ready();
            return;
        }

        this.engines = new HashTable<string,weak IBus.EngineDesc>(str_hash, str_equal);

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

    /**
     * Something on ibus changed so we'll reset our state
     */
    private void reset_ibus()
    {
        this.engines = new HashTable<string,weak IBus.EngineDesc>(str_hash, str_equal);
    }

    private void on_engines_get(GLib.Object? o, GLib.AsyncResult? res)
    {
        try {
            var engines = this.bus.list_engines_async_finish(res);
            this.reset_ibus();
            /* Store reference to the engines */
            foreach (var engine in engines) {
                this.engines[engine.get_name()] = engine;
            }
            GLib.message("Got %u engines", this.engines.length);
        } catch (Error e) {
            GLib.message("Failed to get engines: %s", e.message);
            this.reset_ibus();
            return;
        }
        this.ready();
    }

    /**
     * We gained connection to the ibus daemon
     */
    private void ibus_connected()
    {
        /* Do nothing for now */
        GLib.message("ibus connected");
        if (!did_ibus_init) {
            IBus.init();
            did_ibus_init = true;
        }
        this.bus.list_engines_async.begin(-1, null, on_engines_get);
    }

    /**
     * Lost connection to ibus
     */
    private void ibus_disconnected()
    {
        /* Also do nothing for now */
        GLib.message("ibus disconnected");
        this.reset_ibus();
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

    /**
     * Attempt to grab the ibus engine for the given name if it
     * exists, or returns null
     */
    public weak IBus.EngineDesc? get_engine(string name)
    {
        return this.engines.lookup(name);
    }

    static const int ENGINE_SET_TIMEOUT = 4000;

    public void set_engine(string name)
    {
        if (!this.ibus_available) {
            this.kbm.release_keyboard();
            return;
        }

        message("Beginning set of engine %s", name);
        this.bus.set_global_engine_async.begin(name, ENGINE_SET_TIMEOUT, null, ()=> {
            message("Set the layout..?");
            this.kbm.release_keyboard();
        });
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
