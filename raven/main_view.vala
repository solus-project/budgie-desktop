/*
 * This file is part of arc-desktop
 * 
 * Copyright (C) 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Arc
{

public class MainView : Gtk.ScrolledWindow
{

    /* This is completely temporary. Shush */
    private MprisWidget? mpris = null;
    private CalendarWidget? cal = null;
    private SoundWidget? sound = null;

    public MainView()
    {
        Object();
        set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        /* Eventually these guys get dynamically loaded */
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(box);

        cal = new CalendarWidget();
        cal.margin_top = 6;
        box.pack_start(cal, false, false, 0);

        sound = new SoundWidget();
        sound.margin_top = 6;
        box.pack_start(sound, false, false, 0);

        mpris = new MprisWidget();
        mpris.margin_top = 6;
        box.pack_start(mpris, false, false, 0);

        show_all();
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
