/*
 * TrayApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class TrayApplet : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget()
    {
        return new TrayAppletImpl();
    }
}

public class TrayAppletImpl : Budgie.Applet
{
    protected Na.Tray? tray = null;
    protected int icon_size = 24;
    Gtk.EventBox box;

    public TrayAppletImpl()
    {
        margin = 1;
        box = new Gtk.EventBox();
        add(box);

        valign = Gtk.Align.CENTER;
        box.valign = Gtk.Align.CENTER;
        box.vexpand = false;
        vexpand = false;

        orientation_changed.connect((o)=> {
            tray.set_orientation(o);
        });
        integrate_tray();
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = icon_size;
        n = icon_size;
    }

    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = icon_size;
        n = icon_size;
    }

    protected void integrate_tray()
    {
        if (tray != null) {
            return;
        }
        tray = new Na.Tray.for_screen(get_screen(), Gtk.Orientation.HORIZONTAL);
        tray.set_icon_size(icon_size);
        tray.set_padding(5);
        box.add(tray);
        show_all();
    }
} // End class

[ModuleInit]
public void peas_register_types(TypeModule module) 
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TrayApplet));
}
