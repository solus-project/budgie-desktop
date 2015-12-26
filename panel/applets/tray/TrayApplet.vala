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

public class TrayPlugin : Arc.Plugin, Peas.ExtensionBase
{
    public Arc.Applet get_panel_widget(string uuid)
    {
        return new TrayApplet();
    }
}

public class TrayApplet : Arc.Applet
{
    protected Na.Tray? tray = null;
    /* Fix this. Please. */
    protected int icon_size = 24;
    Gtk.EventBox box;

    public TrayApplet()
    {
        margin = 1;
        box = new Gtk.EventBox();
        add(box);

        valign = Gtk.Align.CENTER;
        box.valign = Gtk.Align.CENTER;
        box.vexpand = false;
        vexpand = false;

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
        if (tray == null) {
            var label = new Gtk.Label("Tray unavailable");
            add(label);
            label.show_all();
            return;
        }
        tray.set_icon_size(icon_size);
        tray.set_padding(5);
        box.add(tray);
        show_all();
    }
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Arc.Plugin), typeof(TrayPlugin));
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
