/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie {
    [CCode (cheader_filename = "theme.h")]
    public static string form_theme_path(string suffix);

    [CCode (cheader_filename = "theme-manager.h")]
    public class ThemeManager : GLib.Object {
		[CCode (has_construct_function = false)]
        public ThemeManager();
    }
}
