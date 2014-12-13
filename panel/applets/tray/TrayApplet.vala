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
    protected Gtk.Orientation orientation;
    protected int padding;

    public TrayAppletImpl()
    {
        margin = 1;
        padding = 0;
        orientation = Gtk.Orientation.HORIZONTAL;

        orientation_changed.connect((o) => {
            orientation = o;
            tray.set_orientation(o);
        });
        icon_size_changed.connect((i, s) => {
            icon_size = (int)i;
        });

        // When we get parented, go add the tray
        notify.connect((o, p) => {
            if (p.name == "parent") {
                integrate_tray();
            }
        });

        // looks a bit weird otherwise.
        set_property("margin-bottom", 1);
    }

    protected void integrate_tray()
    {
        tray = new Na.Tray.for_screen(get_screen(), orientation);
        tray.set_padding(5);
        add(tray);
        show_all();
    }

    // WORKAROUND:
    // Na.Tray always set allocation according with its own
    // parent. Set a fixed size (according with icon_size)
    // to have a better look.
    protected override void size_allocate(Gtk.Allocation allocation)
    {
        int icon_size = (int) (this.icon_size * 0.75);
        Gtk.Allocation tray_allocation = allocation;
        if (orientation == Gtk.Orientation.HORIZONTAL) {
            tray_allocation.height = icon_size;
            padding = (allocation.height - icon_size) / 2 - allocation.y;
        } else {
            tray_allocation.width = icon_size;
            padding = (allocation.width - icon_size) / 2 - allocation.x;
        }
        set_allocation(allocation);
        tray.size_allocate(tray_allocation);
    }
    protected override bool draw(Cairo.Context cr)
    {
        if (orientation == Gtk.Orientation.HORIZONTAL) {
            cr.translate(0, padding);
        } else {
            cr.translate(padding, 0);
        }
        return base.draw(cr);
    }
    // END WORKAROUND

} // End class

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(TrayApplet));
}
