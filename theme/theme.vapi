/*
 * This file is part of budgie-desktop.
 *
 * Copyright (C) 2015 Ikey Doherty
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie {
    [CCode (cheader_filename = "theme.h")]
    public static void please_link_me_libtool_i_have_great_themes();

    [CCode (cheader_filename = "theme.h")]
    public static string form_theme_path(string suffix);
}
