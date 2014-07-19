/*
 * BudgieMenu.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

const int icon_size = 32;
const string BUDGIE_STYLE_MENU_ICON = "menu-icon";

public class BudgieMenu : Budgie.Plugin, Peas.ExtensionBase
{

    protected Gtk.ToggleButton widget;
    protected Budgie.Popover? popover;

    construct {
        init_ui();
    }

    protected void init_ui()
    {
        widget = new Gtk.ToggleButton();
        var img = new Gtk.Image.from_icon_name("view-grid-symbolic", Gtk.IconSize.INVALID);
        img.pixel_size = icon_size;
        widget.add(img);

        // Better styling to fit in with the budgie-panel
        var st = widget.get_style_context();
        st.remove_class(Gtk.STYLE_CLASS_BUTTON);
        st.add_class(BUDGIE_STYLE_MENU_ICON);
        widget.relief = Gtk.ReliefStyle.NONE;

        popover = new BudgieMenuWindow();

        widget.button_release_event.connect((e)=> {
            if (e.button == 1) {
                popover.present(widget);
                return true;
            }
            return false;
        });

        // This enables us to respond to the "panel-main-menu" action
        action_invoked.connect((t) => {
            if (t != Budgie.ActionType.INVOKE_MAIN_MENU) {
                return;
            }
            Idle.add(()=> {
                popover.present(widget);
                return false;
            });
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
    objmodule.register_extension_type(typeof(Budgie.Plugin), typeof(BudgieMenu));
}
