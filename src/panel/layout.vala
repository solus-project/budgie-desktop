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

    /**
     * Attempt to construct a new layout from the given filename
     */
    public Layout.from_url(string url) throws NotRealErrors
    {
        throw new NotRealErrors.NOT_YET_IMPLEMENTED("Not yet implemented");
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
