/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace Budgie {
    [CCode (cheader_filename = "BudgieAppSystem.h")]
    public class AppSystem : GLib.Object {
        public AppSystem();
        public DesktopAppInfo? query_window(Wnck.Window? window);
    }
}
