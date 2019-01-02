/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2019 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int icon_size = 32;

public class TasklistPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new TasklistApplet();
    }
}

public class TasklistApplet : Budgie.Applet
{

    Wnck.Tasklist? tlist;

    public TasklistApplet()
    {
        tlist = new Wnck.Tasklist();
        add(tlist);

        tlist.set_grouping(Wnck.TasklistGroupingType.AUTO_GROUP);

        show_all();
    }

    /**
     * Update the tasklist orientation to match the panel direction
     */
    public override void panel_position_changed(Budgie.PanelPosition position)
    {
        Gtk.Orientation orientation = Gtk.Orientation.HORIZONTAL;
        if (position == Budgie.PanelPosition.LEFT || position == Budgie.PanelPosition.RIGHT) {
            orientation = Gtk.Orientation.VERTICAL;
        }
        tlist.set_orientation(orientation);
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TasklistPlugin));
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
