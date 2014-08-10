/*
 * TaskList.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class TaskListApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new TaskListAppletImpl();
    }
}

public class TaskListAppletImpl : Budgie.Applet
{

    protected Wnck.Tasklist widget;

    public TaskListAppletImpl()
    {
        widget = new Wnck.Tasklist();
        widget.set_grouping(Wnck.TasklistGroupingType.AUTO_GROUP);

        add(widget);
        show_all();
        orientation_changed.connect((o) => {
            widget.set_orientation(o);
        });
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TaskListApplet));
}
