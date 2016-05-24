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
    public AppSystem()
    {
    }

    public DesktopAppInfo? query_window(Wnck.Window window)
    {
        return null;
    }

    public string? query_desktop_id(Wnck.Window window)
    {
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

