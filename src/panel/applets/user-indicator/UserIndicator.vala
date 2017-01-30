/*
 * This file is part of budgie-desktop
 * 
 * Copyright (C) 2015-2016 Solus Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public static const string USER_SYMBOLIC_ICON = "system-shutdown-symbolic";

public class UserIndicator : Budgie.Plugin, Peas.ExtensionBase
{
    public Budgie.Applet get_panel_widget(string uuid)
    {
        return new UserIndicatorApplet(uuid);
    }
}

public class UserIndicatorApplet : Budgie.Applet {

    protected Gtk.EventBox? ebox;
    protected UserIndicatorWindow? popover;
    Gtk.Image image;

    private unowned Budgie.PopoverManager? manager = null;
    public string uuid { public set ; public get; }

    public UserIndicatorApplet(string uuid) {
        Object(uuid: uuid);
        
        ebox = new Gtk.EventBox();
        image = new Gtk.Image.from_icon_name(USER_SYMBOLIC_ICON, Gtk.IconSize.MENU);
        ebox.add(image); 

        popover = new UserIndicatorWindow(image);

        ebox.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            Toggle();
            return Gdk.EVENT_STOP;
        });

        popover.get_child().show_all();

        add(ebox);
        show_all();
    }
    
    public void Toggle(){
        if (popover.get_visible()) {
            popover.popdown();
        } else {
            popover.get_child().show_all();
            this.manager.show_popover(ebox);
        }        
    }
    
    public override void invoke_action(Budgie.PanelAction action) {
        Toggle();
    }
    
    public override void update_popovers(Budgie.PopoverManager? manager) {
        this.manager = manager;
        manager.register_popover(ebox, popover);
    }    
}

[ModuleInit]
public void peas_register_types(TypeModule module)
{
    // boilerplate - all modules need this
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(UserIndicator));
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