/*
 * Workspaces.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class WorkspacesApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new WorkspacesAppletImpl();
    }
}

public class WorkspacesAppletImpl : Budgie.Applet
{

    protected Wnck.Pager widget;

    public WorkspacesAppletImpl()
    {
        widget = new Wnck.Pager();

        add(widget);
        show_all();
        orientation_changed.connect((o) => {
            widget.set_orientation(o);
        });

        margin_top = 2;
        margin_bottom = 2;
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(WorkspacesApplet));
}
