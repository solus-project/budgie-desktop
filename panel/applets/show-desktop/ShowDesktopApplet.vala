/*
 * ShowDesktopApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ShowDesktopApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new ShowDesktopAppletImpl();
    }
}

public class ShowDesktopAppletImpl : Budgie.Applet
{

    protected Gtk.ToggleButton widget;
    protected Gtk.Image img;
    private Wnck.Screen wscreen;

    public ShowDesktopAppletImpl()
    {
        widget = new Gtk.ToggleButton();
        widget.set_active(false);
        img = new Gtk.Image.from_icon_name("user-desktop", Gtk.IconSize.INVALID);
        img.pixel_size = 22;
        widget.add(img);
        widget.set_tooltip_text("Toggle the desktop");

        wscreen = Wnck.Screen.get_default();
        icon_size_changed.connect((i,s)=> {
            img.pixel_size = (int)i;
        });

        wscreen.showing_desktop_changed.connect(()=> {
            bool showing = wscreen.get_showing_desktop();
            widget.set_active(showing);
        });

        widget.clicked.connect(()=> {
            wscreen.toggle_showing_desktop(widget.get_active());
        });

        add(widget);
        show_all();
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ShowDesktopApplet));
}
