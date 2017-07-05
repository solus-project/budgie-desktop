/*
 * This file is part of budgie-desktop
 * 
 * Copyright © 2015-2017 Budgie Desktop Developers
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class ShowDesktopPlugin : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new ShowDesktopApplet();
    }
}

public class ShowDesktopApplet : Budgie.Applet
{
    protected Gtk.ToggleButton widget;
    protected Gtk.Image img;
    private Wnck.Screen wscreen;

    public ShowDesktopApplet()
    {
        widget = new Gtk.ToggleButton();
        widget.relief = Gtk.ReliefStyle.NONE;
        widget.set_active(false);
        img = new Gtk.Image.from_icon_name("user-desktop-symbolic", Gtk.IconSize.BUTTON);
        widget.add(img);
        widget.set_tooltip_text(_("Toggle the desktop"));

        wscreen = Wnck.Screen.get_default();

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
}


[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(ShowDesktopPlugin));
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
