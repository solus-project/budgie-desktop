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

    /**
     * Construct a new IBusManager which will begin setting up the
     * ibus daemon, as well as registering events to connect to it
     * and monitor it.
     */
    public IBusManager()
    {
        Object();

        /* Get the bus */
        bus = new IBus.Bus.async();

        /* Hook up basic signals */
        bus.connected.connect(this.ibus_connected);
        bus.disconnected.connect(this.ibus_disconnected);

        /* Start the ibus daemon
         * TODO: Actually check ibus is available on the system
        */
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
        }
    }

    /**
     * We gained connection to the ibus daemon
     */
    private void ibus_connected()
    {
        /* Do nothing for now */
        GLib.message("ibus connected");
    }

    /**
     * Lost connection to ibus
     */
    private void ibus_disconnected()
    {
        /* Also do nothing for now */
        GLib.message("ibus disconnected");
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
