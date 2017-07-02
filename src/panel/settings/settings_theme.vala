/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie {

/**
 * ThemePage simply provides a bunch of theme controls
 */
public class ThemePage : Budgie.SettingsPage {

    public ThemePage()
    {
        Object(group: SETTINGS_GROUP_APPEARANCE,
               content_id: "theme",
               title: _("Theming"),
               icon_name: "preferences-desktop-theme");
    }
    
} /* End class */

} /* End namespace */
