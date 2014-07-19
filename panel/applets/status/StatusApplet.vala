/*
 * StatusApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class StatusApplet : Budgie.Plugin, Peas.ExtensionBase
{

    protected Gtk.Box widget;
    protected SoundIndicator sound;

    construct {
        init_ui();
    }

    protected void init_ui()
    {
        widget = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        sound = new SoundIndicator();
        widget.pack_start(sound, false, false, 0);
        widget.margin_left = 4;
        widget.margin_right = 2;

        orientation_changed.connect((o)=> {
            widget.set_orientation(o);
        });
    }

        
    public Gtk.Widget get_panel_widget()
    {
        return widget;
    }


} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(StatusApplet));
}
