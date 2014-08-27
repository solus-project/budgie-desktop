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
    protected Na.Tray? tray;
    protected int icon_size = 22;

    public TrayAppletImpl()
    {
        orientation_changed.connect((o)=> {
            tray.set_orientation(o);
        });
        icon_size_changed.connect((i,s)=> {
            if (tray != null) {
                icon_size = (int)s;
                tray.set_icon_size(icon_size);
            }
        });
        // When we get parented, go add the tray
        notify.connect((o,p)=> {
            if (p.name == "parent") {
                integrate_tray();
            }
        });

        // looks a bit weird otherwise.
        set_property("margin-bottom", 1);
    }

    protected void integrate_tray()
    {
        set_size_request(-1, -1);
        tray = new Na.Tray.for_screen(get_screen(), Gtk.Orientation.HORIZONTAL);
        tray.set_icon_size(icon_size);
        tray.set_padding(5);
        add(tray);
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
