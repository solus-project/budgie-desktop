/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

errordomain NotRealErrors {
    NOT_YET_IMPLEMENTED,
}

errordomain LayoutError {
    MISSING_PANELS,
}

/**
 * A Layout defines the initial configuration for the desktop in a nicely
 * encapsulated fashion
 */
public class Layout : GLib.Object {

    /* Stylized name for the layout */
    public string name { public get; set; }

    /**
     * Create a new layout with the given name
     */
    public Layout(string name) throws NotRealErrors
    {
        Object(name: name);
        throw new NotRealErrors.NOT_YET_IMPLEMENTED("Not yet implemented");
    }

    private string? file_to_string(File f) throws Error
    {
        StringBuilder builder = new StringBuilder();
        string? line = null;
        var dis = new DataInputStream(f.read());
        while ((line = dis.read_line()) != null) {
            builder.append_printf("%s\n", line);
        }
        return "" + builder.str;
    }

    /**
     * Attempt to construct a new layout from the given filename
     */
    public Layout.from_url(string url) throws Error, NotRealErrors, LayoutError
    {
        Object();

        this.load_from_url(url);
    }

    /**
     * Handle the actual loading
     */
    private void load_from_url(string url) throws Error, NotRealErrors, LayoutError
    {
        File f = File.new_for_uri(url);
        KeyFile keyfile = new KeyFile();
        string? contents = null;
        string[] toplevels;

        try {
            contents = this.file_to_string(f);
            keyfile.load_from_data(contents, contents.length, KeyFileFlags.KEEP_TRANSLATIONS);
        } catch (Error e) {
            throw e;
        }

        if (!keyfile.has_key("Panels", "Panels")) {
            throw new LayoutError.MISSING_PANELS("Panels section is missing");
        }

        /* Load all the toplevels */
        toplevels = keyfile.get_string_list("Panels", "Panels");
        foreach (unowned string toplevel in toplevels) {
            this.load_toplevel(keyfile, toplevel);
        }

        throw new NotRealErrors.NOT_YET_IMPLEMENTED("Not yet implemented");
    }

    /**
     * Load a toplevel from the keyfile and store it locally..
     */
    private void load_toplevel(KeyFile? keyfile, string toplevel_id) throws Error
    {
    }

} /* End Layout */


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
